'use strict';
const path = require('node:path');
const fs = require('node:fs');
const { createHash } = require('node:crypto');
const { createRequire } = require('node:module');
const { pathToFileURL } = require('node:url');
const fromE2E = createRequire(path.join(__dirname, '../../e2e/package.json'));
const { test, expect } = fromE2E('@playwright/test');
const { readinessDecision, chromeProblems, fullyVisible, scrollSettled, measuredHeaderMember, emergingFlowProven, emergingMotionDistance } = require('./audit_policy.cjs');
const kit = import(pathToFileURL(path.join(__dirname, '../../e2e/utils/interaction.mjs')).href);
const catalogue = JSON.parse(fs.readFileSync(path.resolve(process.env.AUDIT_CATALOGUE || 'build/flutter-pages-audit/catalogue.json'), 'utf8'));
const REFERENCE_SHA = 'c4a7b939e1ad22363321de8b50efe8fcbfb12134';
const BASE = 'https://myon-bioinformatics.github.io/flutter_navigation_basic/';
if (catalogue.schema !== 'flutter-pages-audit-catalogue/1' || !catalogue.routes?.length || catalogue.referenceSha !== REFERENCE_SHA) {
  throw new Error('Missing, empty, or stale audit catalogue; never allow zero-coverage success');
}
const { collectSemanticInventory } = require('./semantic_collector.cjs');
const {projectSource, evaluateFamilyProof} = require('./family_proof.cjs');
const {runSpatialProbe} = require('./spatial_probe.cjs');
const proofMode = process.env.AUDIT_PROOF_DISCOVERY === '1';
const proofManifest = proofMode ? require('./source-adapter.json') : null;
const proofSelection = proofMode ? require('./proof-selection.json') : null;
if (proofMode && proofSelection.liveExecutionEnabled !== true) throw new Error('New proof measurements are disabled by the user; no alternate config bypass');
const familyManifestBytes = fs.readFileSync(path.join(__dirname, 'family-inventory.json'));
const familyManifest = JSON.parse(familyManifestBytes);
const familyManifestSha256 = createHash('sha256').update(familyManifestBytes).digest('hex');
if (familyManifest.referenceSha !== REFERENCE_SHA || familyManifest.caseCount !== 48 || familyManifest.contracts.length !== 24 || new Set(familyManifest.contracts.map(c => c.route)).size !== 24) throw new Error('Invalid reviewed family discovery manifest');
function familySpec(route, viewport) {
  const source = familyManifest.contracts.find(c => c.route === route);
  if (!source) throw new Error('Route outside explicit 48-case discovery manifest');
  return projectSource(source, viewport);
}
const familyTestInfo = new WeakMap();
async function familySnapshot(page, record, phase) {
  // The full 430-case lane retains all routes. Extra family discovery is only
  // defined for its explicit 24 representatives; absence is never a pass.
  if (!familyManifest.contracts.some(source => source.route === record.route)) return;
  const observation = record.observations.familyObservation ||= {
    manifestSha256: familyManifestSha256,
    scope: 'read-only source-family discovery; no acceptance promotion', snapshots: [],
  };
  const collector = await page.evaluate(collectSemanticInventory, familySpec(record.route, record.viewport));
  const sampleMs = collector.sampleMs;
  if (!['after-reset-initial', 'after-reset-stable'].includes(phase)) phase += '-' + observation.snapshots.length;
  const name = `family-${String(observation.snapshots.length).padStart(2, '0')}-${phase}.png`;
  await capture(page, familyTestInfo.get(record), record, name);
  observation.snapshots.push({ phase, sampleMs, collector, capture: { ...record.captures.at(-1) } });
}
const ids = ['shared-header-title', 'shared-header-home', 'shared-header-favorite', 'shared-header-menu'];
const node = (page, id) => page.locator(`[flt-semantics-identifier="${id}"]`);
const favorite = page => node(page, 'shared-header-favorite').getByRole('button');
const boxDelta = (a, b) => !a || !b ? Infinity : Math.max(...['x', 'y', 'width', 'height'].map(k => Math.abs(a[k] - b[k])));
async function settle(page) {
  await page.waitForTimeout(300);
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
}
async function bootstrap(page, record) {
  const started = Date.now(), phase = { snapshots: [], attempts: 0, status: 'waiting' };
  (record.observations.readiness ||= []).push(phase);
  await page.locator('flt-glass-pane').waitFor({ state: 'attached', timeout: 15_000 });
  await page.bringToFront();
  for (;;) {
    const snapshot = await page.evaluate(() => {
      const queryDeep = selector => {
        const matches = [], visit = root => {
          matches.push(...root.querySelectorAll(selector));
          for (const el of root.querySelectorAll('*')) if (el.shadowRoot) visit(el.shadowRoot);
        };
        visit(document); return matches;
      };
      let active = document.activeElement;
      while (active?.shadowRoot?.activeElement) active = active.shadowRoot.activeElement;
      const titles = queryDeep('[flt-semantics-identifier="shared-header-title"]');
      const b = titles.length === 1 ? titles[0].getBoundingClientRect() : null;
      return {
        titleCount: titles.length, titleVisible: !!b && b.width > 0 && b.height > 0,
        favoriteCount: queryDeep('[flt-semantics-identifier="shared-header-favorite"] [role="button"]').length,
        placeholderCount: queryDeep('flt-semantics-placeholder[aria-label="Enable accessibility"]').length,
        semanticsCount: document.querySelectorAll('flt-semantics').length,
        documentHasFocus: document.hasFocus(), activeId: active?.id || null,
        activeLabel: active?.getAttribute('aria-label'), activeTag: active?.tagName,
      };
    });
    const elapsedMs = Date.now() - started;
    phase.snapshots.push({ elapsedMs, ...snapshot });
    const decision = readinessDecision(snapshot, { attempts: phase.attempts, elapsedMs });
    if (decision === 'ready') { phase.status = 'ready'; await settle(page); return; }
    if (decision === 'timeout') {
      phase.status = 'failed';
      throw new Error('Shared header/favorite readiness timed out after bounded real accessibility activation: ' + JSON.stringify(snapshot));
    }
    if (decision === 'activate') {
      const placeholder = page.locator('flt-semantics-placeholder[aria-label="Enable accessibility"]');
      try {
        await placeholder.focus({ timeout: 1_000 });
        await settle(page); // Register the initial Flutter frame before sending its activation key.
        if (await placeholder.count() === 1 && await placeholder.evaluate(el => {
          let active = document.activeElement;
          while (active?.shadowRoot?.activeElement) active = active.shadowRoot.activeElement;
          return el.isConnected && active === el;
        })) {
          await page.keyboard.press('Enter');
          phase.attempts++;
          record.inputs.push({ input: 'Enter', purpose: 'accessibility bootstrap only; never inject favorite focus', attempt: phase.attempts, elapsedMs });
        }
      } catch (error) { phase.snapshots.push({ elapsedMs: Date.now() - started, activationRace: String(error).slice(0, 500) }); }
    }
    await page.waitForTimeout(400);
  }
}

async function check(record, name, fn) {
  try { record.checks[name] = { status: 'passed', ...await fn() }; }
  catch (error) { record.checks[name] = { status: 'failed', reason: String(error).slice(0, 3000) }; }
}
async function capture(page, info, record, name) {
  const bytes = await page.screenshot({ path: info.outputPath(name), timeout: 5_000 });
  record.captures.push({ file: name, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex') });
}
async function baseline(request) {
  const response = await request.get(`${BASE}assets/assets/diagnostics/build_metadata.json`, { headers: { 'Cache-Control': 'no-cache' }, timeout: 15_000 });
  expect(response.ok(), 'published build metadata must be readable').toBe(true);
  const sha = (await response.json()).repository?.revision?.sha;
  expect(sha, 'STALE_BASELINE: stop and explicitly review a changed public deployment; never auto-update').toBe(REFERENCE_SHA);
  return sha;
}
async function geometry(page) {
  const result = await page.evaluate(() => {
    const box = el => { const b = el.getBoundingClientRect(); return { x: b.x, y: b.y, width: b.width, height: b.height }; };
    const intersection = (a, b) => ({ x: Math.max(a.x, b.x), y: Math.max(a.y, b.y),
      width: Math.max(0, Math.min(a.x + a.width, b.x + b.width) - Math.max(a.x, b.x)),
      height: Math.max(0, Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y)) });
    const viewport = { x: 0, y: 0, width: innerWidth, height: innerHeight };
    const clipped = el => {
      let result = intersection(box(el), viewport);
      for (let parent = el.parentElement; parent; parent = parent.parentElement) {
        const style = getComputedStyle(parent);
        if (/(hidden|clip|scroll|auto)/.test(`${style.overflowX} ${style.overflowY}`)) result = intersection(result, box(parent));
      }
      return result;
    };
    const title = document.querySelector('[flt-semantics-identifier="shared-header-title"]');
    let headerBottom = 56, headerFrame = null, headerNode = null;
    for (let parent = title; parent; parent = parent.parentElement) {
      const b = box(parent);
      if (parent.tagName === 'FLT-SEMANTICS' && b.y >= -1 && b.y <= 1 && b.width >= innerWidth * .8 && b.height < innerHeight / 2 && parent.querySelector('[flt-semantics-identifier="shared-header-home"]')) { headerBottom = Math.max(headerBottom, b.height); headerFrame = b; headerNode = parent; }
    }
    const secondary = document.querySelector('[flt-semantics-identifier="shared-header-secondary"]');
    if (secondary) { const b = box(secondary); headerBottom = Math.max(headerBottom, b.y + b.height); }
    const doors = [...document.querySelectorAll('[flt-semantics-identifier="tool-door-dropdown"]')];
    const door = doors.length === 1 ? doors[0] : null;
    let footer = door ? box(door) : null, footerNode = door;
    const scrollParents = el => {
      const parents = [];
      for (let parent = el?.parentElement; parent; parent = parent.parentElement) {
        const css = getComputedStyle(parent), b = box(parent);
        if (parent.tagName === 'FLT-SEMANTICS' && ['auto', 'scroll'].includes(css.overflowY) && b.width >= 30 && b.height >= 12) parents.push({ id: parent.id, box: b, clip: clipped(parent), scrollHeight: parent.scrollHeight, clientHeight: parent.clientHeight });
      }
      return parents;
    };
    const footerScrollParents = scrollParents(door);
    const footerMode = doors.length > 1 ? 'ambiguous' : !door ? 'absent' : footerScrollParents.length ? 'scroll-content' : 'fixed';
    for (let parent = footerMode === 'fixed' ? door?.parentElement : null; parent; parent = parent.parentElement) {
      const b = box(parent);
      if (parent.tagName === 'FLT-SEMANTICS' && b.y >= headerBottom && b.width >= innerWidth * .6 && b.height < innerHeight * .5) { footer = b; footerNode = parent; }
    }
    const envelope = { x: 0, y: headerBottom, width: innerWidth, height: Math.min(footerMode === 'fixed' ? footer.y : innerHeight - 24, innerHeight - 24) - headerBottom };
    const footerClip = !door ? null : footerMode === 'scroll-content' ? intersection(clipped(door), envelope) : clipped(footerNode);
    const header = {};
    for (const id of ['shared-header-title', 'shared-header-home', 'shared-header-favorite', 'shared-header-menu', 'shared-header-secondary']) {
      const matches = [...document.querySelectorAll(`[flt-semantics-identifier="${id}"]`)];
      header[id] = { count: matches.length, box: matches.length === 1 ? box(matches[0]) : null, text: matches.length === 1 ? matches[0].textContent : null };
    }
    const semantics = [...document.querySelectorAll('flt-semantics')];
    const regions = semantics.map(el => {
      const b = box(el), css = getComputedStyle(el);
      return { id: el.id, box: b, clip: intersection(clipped(el), envelope), overflowY: css.overflowY, overflowX: css.overflowX,
        scrollTop: el.scrollTop, scrollHeight: el.scrollHeight, clientHeight: el.clientHeight, scrollWidth: el.scrollWidth, clientWidth: el.clientWidth,
        descendantBounds: [...el.querySelectorAll('flt-semantics')].filter(child => !child.querySelector('flt-semantics')).map(box) };
    }).filter(r => ['auto', 'scroll'].includes(r.overflowY) && r.box.y >= headerBottom - 1 && r.box.y < headerBottom + envelope.height && r.clip.width >= 30 && r.clip.height >= 12);
    const leaves = semantics.filter(el => !el.querySelector('flt-semantics') && !el.closest('[flt-semantics-identifier^="shared-header-"]')).map(el => ({
      id: el.id, role: el.getAttribute('role'), label: (el.getAttribute('aria-label') || el.textContent || '').slice(0, 160), box: box(el), clip: intersection(clipped(el), envelope),
    })).filter(item => item.box.y >= headerBottom - 1 && item.box.y < headerBottom + envelope.height && item.clip.width > 0 && item.clip.height > 0);
    const inaccessibleIdentifiers = [...document.querySelectorAll('[flt-semantics-identifier]')].filter(el => {
      const id = el.getAttribute('flt-semantics-identifier');
      return !el.closest('[flt-semantics-identifier^="shared-header-"]') && !['back-to-hub', 'tool-door-dropdown'].includes(id) && !footerNode?.contains(el);
    }).map(el => ({ id: el.getAttribute('flt-semantics-identifier'), box: box(el), headerDescendant: !!headerNode?.contains(el),
      // Semantics can retain positive boxes behind Scaffold's fixed footer.
      // The observed body envelope, not raw viewport inclusion, bounds access.
      clip: intersection(clipped(el), envelope), scrollParents: scrollParents(el) }))
      .filter(item => item.box.width > 0 && item.box.height > 0 && (item.clip.width < 12 || item.clip.height < 12) && !item.scrollParents.some(parent => {
        const access = intersection(parent.clip, envelope);
        return parent.scrollHeight > parent.clientHeight + 2 && access.width >= 30 && access.height >= 12;
      }));
    const surface = document.scrollingElement || document.documentElement;
    return { viewport: { width: innerWidth, height: innerHeight, deviceScaleFactor: devicePixelRatio }, header, headerFrame, footer, footerClip, footerMode, footerScrollParents, footerId: door?.id || null, footerCount: doors.length, envelope, regions, leaves, inaccessibleIdentifiers,
      rootOverflow: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1 || surface.scrollWidth > surface.clientWidth + 1,
      bodyWidthDiagnostic: { scrollWidth: document.body.scrollWidth, clientWidth: document.body.clientWidth },
      // Invisible semantics labels are not painted-glyph bounds. Do not gate on their text scrollWidth.
      semanticsCount: semantics.length };
  });
  // Hub's search is a source-defined subHeader, not body content. Exclude only
  // actual measured header descendants fully contained by that header frame;
  // an off-screen/misplaced header control must not disappear from diagnostics.
  result.inaccessibleIdentifiers = result.inaccessibleIdentifiers.filter(item =>
    !measuredHeaderMember(item, result.headerFrame));
  return result;
}
async function regionWitness(page, id) {
  return page.evaluate(id => {
    const el = document.getElementById(id);
    if (!el) return null;
    const b = el.getBoundingClientRect();
    return { scrollTop: el.scrollTop, scrollHeight: el.scrollHeight, clientHeight: el.clientHeight,
      box: { x: b.x, y: b.y, width: b.width, height: b.height },
      children: [...el.querySelectorAll('flt-semantics')].filter(child => !child.querySelector('flt-semantics')).map(child => {
        const r = child.getBoundingClientRect(); return [child.id, r.x, r.y, r.width, r.height];
      }) };
  }, id);
}
function moved(a, b) { return !!a && !!b && (Math.abs(a.scrollTop - b.scrollTop) > 1 || JSON.stringify(a.children) !== JSON.stringify(b.children)); }
async function settledScrollGeometry(page, record, regionIds, phase = 'terminal') {
  const started = Date.now(), samples = [];
  // The pinned Flutter engine has a 500ms pointer-mode interval. This floor is
  // not proof of readiness: original-region CSS and stable bounds are required.
  await page.waitForTimeout(600);
  let previous = null;
  while (Date.now() - started < 3_000) {
    const current = await geometry(page);
    samples.push({ elapsedMs: Date.now() - started, geometry: current });
    if (scrollSettled(previous, current, regionIds)) {
      const result = { phase, status: 'stable', samples };
      (record.observations.scrollSettlingPhases ||= []).push(result);
      if (phase === 'terminal') record.observations.scrollSettling = result;
      return current;
    }
    previous = current;
    await page.waitForTimeout(100);
  }
  const result = { phase, status: 'unverified', samples };
  (record.observations.scrollSettlingPhases ||= []).push(result);
  if (phase === 'terminal') record.observations.scrollSettling = result;
  return null;
}

async function emergingDoorMotion(page, record, before, start) {
  const candidates = start.regions.filter(r => before.regions.some(a => a.id === r.id) &&
    start.footerScrollParents.some(p => p.id === r.id));
  const motion = { start, back: null, end: null, inputs: [], regionId: null };
  record.observations.emergingDoorMotion = motion;
  if (candidates.length !== 1) return motion;
  const region = candidates[0]; motion.regionId = region.id;
  const distance = emergingMotionDistance(start, region.id);
  motion.plannedDistance = distance;
  if (distance === null) { motion.reason = 'Insufficient measured unclipped travel (minimum 12px plus 4px margin); no input sent.'; return motion; }
  const x = Math.floor(region.clip.x + Math.min(8, region.clip.width / 2));
  const y = Math.floor(region.clip.y + region.clip.height / 2);
  await page.mouse.move(x, y);
  // Two bounded real gestures, no synthetic scroll and no action activation.
  // Always attempt restoration even if the backward witness is insufficient.
  for (const [phase, deltaY] of [['back', -distance], ['end', distance]]) {
    await page.mouse.wheel(0, deltaY);
    const input = { input: 'wheel', region: region.id, x, y, deltaY, purpose: 'emerging Door motion ' + phase };
    motion.inputs.push(input); record.inputs.push(input);
    motion[phase] = await settledScrollGeometry(page, record, [region.id], 'emerging-' + phase);
  }
  return motion;
}

async function scrollProof(page, record, before) {
  const overflowing = before.regions.filter(r => r.scrollHeight > r.clientHeight + 2);
  if (!overflowing.length) {
    const fullyContained = r => r.clip.width >= r.box.width - 1 && r.clip.height >= r.box.height - 1 && r.descendantBounds.length > 0 && r.descendantBounds.every(b => b.width > 0 && b.height > 0 && b.x >= r.box.x - 1 && b.y >= r.box.y - 1 && b.x + b.width <= r.box.x + r.box.width + 1 && b.y + b.height <= r.box.y + r.box.height + 1);
    if (before.regions.length > 0 && before.regions.every(r => r.scrollHeight <= r.clientHeight + 2 && fullyContained(r))) {
      return { status: 'not_applicable', reason: 'Every identified vertical semantics region has no overflow and its complete exposed leaf bounds fit its region. Paint and undisclosed content remain separately unverified.', evidence: { fits: true, overflow: false, scope: 'exposed semantics only', regions: before.regions } };
    }
    const x = Math.floor(before.envelope.x + Math.min(8, before.envelope.width / 2));
    const y = Math.floor(before.envelope.y + Math.max(1, before.envelope.height / 2));
    await page.mouse.move(x, y); await page.mouse.wheel(0, 240); await settle(page);
    record.inputs.push({ input: 'wheel', x, y, deltaY: 240, purpose: 'probe unidentified body without declaring a no-op to be fit' });
    record.observations.unidentifiedScrollProbe = { before, after: await geometry(page) };
    return { status: 'unverified', reason: 'Real wheel was attempted but no complete identified region or fit evidence is available; no-op is not success.', evidence: { wheelAttempted: true } };
  }
  const results = [];
  for (const region of overflowing.slice(0, 4)) {
    const x = Math.floor(region.clip.x + Math.min(8, region.clip.width / 2));
    const y = Math.floor(region.clip.y + region.clip.height / 2);
    const start = await regionWitness(page, region.id);
    await page.mouse.move(x, y); await page.mouse.wheel(0, 240); await settle(page);
    record.inputs.push({ input: 'wheel', x, y, deltaY: 240, region: region.id });
    const after = await regionWitness(page, region.id);
    await familySnapshot(page, record, 'wheel-first-raw');
    let boundary = false, previous = after, current = after;
    const steps = [];
    if (moved(start, after)) {
      for (let attempt = 0; attempt < 4; attempt++) {
        const deltaY = Math.min(20_000, Math.max(480, (current?.scrollHeight || 0) - (current?.clientHeight || 0) - (current?.scrollTop || 0) + 240));
        await page.mouse.wheel(0, deltaY); await settle(page);
        current = await regionWitness(page, region.id);
        await familySnapshot(page, record, 'wheel-step-raw');
        steps.push({ deltaY, after: current }); record.inputs.push({ input: 'wheel', x, y, deltaY, region: region.id });
        if (current && previous && !moved(previous, current)) {
          boundary = current.scrollHeight - current.clientHeight - current.scrollTop <= 2;
          break; // A stuck gesture with remaining extent is unverified, never an end.
        }
        previous = current;
      }
    }
    results.push({ id: region.id, start, after, moved: moved(start, after), boundaryObserved: boundary, end: current, steps });
  }
  let after = await settledScrollGeometry(page, record, results.map(r => r.id));
  if (!after) return { status: 'unverified', reason: 'Original scroll-region styling/bounds did not settle without further input before the deadline.', evidence: { results } };
  let motion = null;
  if (before.footerMode === 'absent' && after.footerMode === 'scroll-content') {
    motion = await emergingDoorMotion(page, record, before, after);
    if (motion.end) after = motion.end;
  }
  record.observations.beforeScroll = before;
  record.observations.afterScroll = after;
  record.observations.scrollProbe = { results, observedRegions: overflowing.length, titleGlyphDelta: boxDelta(before.header['shared-header-title'].box, after.header['shared-header-title'].box) };
  const problems = chromeProblems(before, after, motion);
  if (motion && !emergingFlowProven(before, after, motion)) {
    // Insufficient flow evidence is unknown, but real header/control drift is
    // still a failure, including drift during the backward leg.
    const otherProblems = problems.filter(p => p !== 'footerMode: structural classification changed');
    for (const g of [motion.back, motion.end].filter(Boolean)) {
      otherProblems.push(...chromeProblems(motion.start, g).filter(p => p !== 'footerMode: structural classification changed'));
    }
    expect(otherProblems, 'measured chrome must remain fixed during motion probe').toEqual([]);
    return { status: 'unverified', reason: 'Bounded real backward/forward input did not prove same-Door flow motion and restored visible end.', evidence: { results, motion } };
  }
  expect(problems, 'measured header frame/buttons and independent footer remain fixed; flowing Door is not fixed chrome').toEqual([]);
  const flowFooterReached = before.footerMode !== 'scroll-content' || fullyVisible(after.footer, after.footerClip);
  const complete = overflowing.length <= 4 && results.every(r => r.moved && r.boundaryObserved && after.regions.some(final =>
    final.id === r.id && final.scrollHeight - final.clientHeight - final.scrollTop <= 2)) && after.leaves.some(leaf => leaf.clip.height >= 12 && leaf.clip.width >= 30) && flowFooterReached;
  return { status: complete ? 'passed' : 'unverified', reason: complete ? 'Real wheel moved each observed vertical body region and reached a stable end with visible content; fixed chrome retained.' : 'Bounded wheel probe did not establish movement/end for every observed region; not treated as fit or success.', evidence: { results, observedRegions: overflowing.length, fixedHeader: true, footerMode: before.footerMode, fixedFooter: before.footerMode === 'fixed', flowFooterReached, scope: 'exposed vertical semantics regions, not every page-specific action' } };
}
async function selected(page, value) {
  await expect(favorite(page)).toHaveText(value ? 'Remove favorite' : 'Favorite this page');
  await expect(favorite(page)).toHaveAttribute('aria-current', String(value));
}

for (const entry of catalogue.routes) test(`observe public route ${entry.route}`, async ({ page, browser, request }, info) => {
  const viewport = catalogue.viewports.find(item => item.id === info.project.name);
  if (!viewport) throw new Error('Unknown viewport; coverage cannot be inferred');
  const record = { schema: 'flutter-pages-audit/1', route: entry.route, canonical: entry.canonical, alias: entry.alias,
    viewport, referenceSha: REFERENCE_SHA, candidateSha: process.env.CANDIDATE_SHA || null,
    servedShaBefore: null, servedShaAfter: null, browserVersion: browser.version(), playwrightVersion: fromE2E('@playwright/test/package.json').version,
    runId: process.env.GITHUB_RUN_ID || null, checks: {}, observations: {}, captures: [], inputs: [], errors: [] };
  familyTestInfo.set(record, info);
  const runtimeErrors = [], requests = [], blocked = [];
  page.on('pageerror', error => runtimeErrors.push(error.message));
  page.on('dialog', async dialog => { record.errors.push({ kind: 'unexpected-dialog', type: dialog.type() }); await dialog.dismiss(); });
  page.on('request', r => { const u = new URL(r.url()); requests.push({ method: r.method(), origin: u.origin, path: u.pathname }); });
  // No generic explorer, form submission, clipboard/file access, persistent settings, or privileged permission grant.
  await page.route('**/*', route => {
    if (['GET', 'HEAD', 'OPTIONS'].includes(route.request().method())) return route.continue();
    blocked.push({ method: route.request().method(), url: new URL(route.request().url()).origin });
    return route.abort('blockedbyclient');
  });
  try {
    await check(record, 'build_identity', async () => { record.servedShaBefore = await baseline(request); });
    if (record.checks.build_identity.status !== 'passed') throw new Error('Pinned baseline could not be established; route checks not attempted');
    await check(record, 'navigation', async () => {
      const response = await page.goto(`${BASE}#${entry.route}`);
      expect(response?.ok()).toBe(true); await bootstrap(page, record);
      const actual = new URL(page.url()).hash.slice(1) || '/';
      expect([entry.route, entry.canonical]).toContain(actual);
      const title = await node(page, 'shared-header-title').innerText();
      expect(title.trim().endsWith(` ${entry.emoji}`), 'route-specific page identity must match catalogue, not a fallback Home').toBe(true);
      record.observations.navigation = { requested: entry.route, actual, title };
    });
    if (record.checks.navigation.status !== 'passed') throw new Error('Route identity could not be established; dependent checks not attempted');
    await capture(page, info, record, 'initial.png');
    const first = await geometry(page); record.observations.initial = first;
    const inventory = await (await kit).inventory(page, { selector: '[flt-semantics-identifier], [role="button"], [role="textbox"], [role="checkbox"]', limit: 2000 });
    record.observations.controlInventory = inventory;
    await check(record, 'viewport', async () => { expect(first.viewport).toEqual({ width: viewport.width, height: viewport.height, deviceScaleFactor: viewport.deviceScaleFactor }); });
    await check(record, 'header_geometry', async () => {
      expect(first.rootOverflow, 'no actual horizontal root overflow; body-label expansion is diagnostic only').toBe(false);
      for (const id of ids) {
        const { count, box } = first.header[id]; expect(count).toBe(1); expect(box).not.toBeNull();
        expect(box.width).toBeGreaterThan(0); expect(box.height).toBeGreaterThan(0);
        expect(box.x).toBeGreaterThanOrEqual(-1); expect(box.y).toBeGreaterThanOrEqual(-1);
        expect(box.x + box.width).toBeLessThanOrEqual(viewport.width + 1); expect(box.y + box.height).toBeLessThanOrEqual(viewport.height + 1);
        if (id !== ids[0]) { expect(box.width).toBeGreaterThanOrEqual(39); expect(box.height).toBeGreaterThanOrEqual(39); }
      }
      for (let i = 1; i < ids.length; i++) expect(first.header[ids[i - 1]].box.x + first.header[ids[i - 1]].box.width, 'common row regions must not overlap').toBeLessThanOrEqual(first.header[ids[i]].box.x + 1);
      const secondary = first.header['shared-header-secondary'];
      if (secondary.count) { expect(secondary.count).toBe(1); expect(secondary.box.y).toBeGreaterThanOrEqual(48); expect(secondary.box.width).toBeLessThanOrEqual(viewport.width + 1); }
    });
    await check(record, 'body_geometry', async () => {
      expect(first.footerCount, 'Door identity must not be duplicated even without a scroll probe').toBeLessThanOrEqual(1);
      expect(inventory.truncated, 'control observation must not silently truncate').toBe(false);
      expect(first.inaccessibleIdentifiers, 'exposed identified body regions must not be fully clipped without a usable scroll path').toEqual([]);
      expect(first.envelope.height, 'positive usable body envelope').toBeGreaterThanOrEqual(32);
      expect(first.leaves.some(leaf => leaf.clip.width >= 30 && leaf.clip.height >= 12), 'body exposes a usable visible content segment, not just an offscreen box').toBe(true);
      for (const region of first.regions) {
        expect(region.clip.width).toBeGreaterThanOrEqual(30); expect(region.clip.height).toBeGreaterThanOrEqual(12);
        expect(region.box.x).toBeGreaterThanOrEqual(-1); expect(region.box.x + region.box.width).toBeLessThanOrEqual(viewport.width + 1);
      }
      return { evidence: { scope: 'measured header/footer envelope and clipped exposed body/scroll regions; not a painted text or complete-control oracle' } };
    });
    await check(record, 'favorite_keyboard', async () => {
      await selected(page, false);
      const focus = [];
      for (let tabs = 1; tabs <= 20; tabs++) {
        await page.keyboard.press('Tab'); await settle(page);
        const current = await favorite(page).evaluate(target => ({ target: document.activeElement === target || target.contains(document.activeElement), id: document.activeElement?.id || null, role: document.activeElement?.getAttribute('role'), label: document.activeElement?.getAttribute('aria-label') }));
        focus.push({ tabs, ...current }); if (current.target) break;
      }
      record.observations.focus = focus; await expect(favorite(page), 'real Tab traversal reaches favorite without injected focus').toBeFocused();
      for (const [key, value] of [['Space', true], ['Enter', false]]) {
        await page.keyboard.press(key); await settle(page); await selected(page, value); await expect(favorite(page)).toBeFocused();
        record.inputs.push({ input: key, purpose: 'favorite keyboard toggle', selected: value });
      }
      await capture(page, info, record, 'keyboard-focus.png');
      return { evidence: { focus, retained: true, visibleFocusPaint: 'screenshot only; not pixel-asserted' } };
    });
    await check(record, 'favorite_pointer', async () => {
      await selected(page, false);
      for (const value of [true, false]) {
        record.inputs.push(await (await kit).press(page, favorite(page), { touch: false }));
        await page.mouse.move(0, 0); await settle(page); await selected(page, value);
      }
    });
    await check(record, 'favorite_reset', async () => {
      await selected(page, false); record.inputs.push(await (await kit).press(page, favorite(page), { touch: false }));
      await selected(page, true); await page.reload(); await bootstrap(page, record); await selected(page, false);
      return { evidence: { reloadWhileSelected: true } };
    });
    await familySnapshot(page, record, 'after-reset-initial');
    await page.waitForTimeout(600);
    await familySnapshot(page, record, 'after-reset-stable');
    if (proofMode) {
      if (!proofSelection.routes.includes(record.route)) throw new Error('Route outside explicit proof-discovery budget');
      const selectedCase = proofManifest.cases.find(item => item.route === record.route && item.viewportId === record.viewport.id);
      if (!selectedCase || proofManifest.referenceSha !== REFERENCE_SHA) throw new Error('Missing or stale source case');
      const metadataResponse = await request.get(`${BASE}assets/assets/diagnostics/build_metadata.json`, {headers:{'Cache-Control':'no-cache'},timeout:15000});
      if (!metadataResponse.ok()) throw new Error('Source metadata unavailable for diagnostic label');
      const metadataRaw = await metadataResponse.text();
      if (JSON.parse(metadataRaw).repository?.revision?.sha !== REFERENCE_SHA) throw new Error('Stale proof metadata');
      const buildMetadata = {raw:metadataRaw,sha256:createHash('sha256').update(metadataRaw).digest('hex')};
      const source = {...selectedCase, route: record.route, referenceSha: REFERENCE_SHA,
        sourceHashes: {...proofManifest.sourceHashes, ...proofManifest.additionalChromeSourceHashes},
        locale: 'eng', stateKey: selectedCase.spatial?.stateKey || createHash('sha256').update(JSON.stringify(selectedCase.initialState)).digest('hex'),
        referenceHeights: [1600, 1720], buildMetadata, unresolved: selectedCase.spatial?.unresolved || ['Complete source representation not yet bound']};
      const spatial = await runSpatialProbe({page, source, viewport: record.viewport, geometry, settle,
        capture: async phase => {
          const file = `${phase}.png`;
          const bytes = await page.screenshot({path: info.outputPath(file), timeout: 5000});
          return {file, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex')};
        }});
      record.observations.familyProof = {schema: 'family-proof-observations/1', spatial, buildMetadata,
        sourceManifestSha256: createHash('sha256').update(fs.readFileSync(path.join(__dirname,'source-adapter.json'))).digest('hex'),
        selectionSha256: createHash('sha256').update(fs.readFileSync(path.join(__dirname,'proof-selection.json'))).digest('hex')};
      record.observations.familyProof.evaluation = evaluateFamilyProof(source, record.observations.familyProof);
      record.observations.familyProof.acceptancePromoted = false;
      if (!spatial.complete) record.errors.push({kind:'proof-discovery',message:'Incomplete or unstable explicitly bounded capture sequence'});
    }
    const beforeScroll = await geometry(page);
    await check(record, 'scroll', () => scrollProof(page, record, beforeScroll));
    await familySnapshot(page, record, 'after-scroll');
    record.checks.page_action = { status: 'unverified', reason: 'Page-specific form, navigation, file, clipboard, networking and destructive controls are inventoried but not arbitrarily activated. Only the shared favorite has a universal safe action contract.' };
    record.checks.painted_text_overflow = { status: 'unverified', reason: 'Flutter semantics boxes do not certify painted text/icon clipping or every overlapping element. Screenshots are evidence for follow-up review, not automatic pixel-parity approval.' };
  } catch (error) { record.errors.push({ kind: 'audit-harness', message: String(error) }); }
  finally {
    await check(record, 'runtime_errors', async () => { expect(runtimeErrors, 'no uncaught browser errors').toEqual([]); expect(blocked, 'unexpected automatic non-read-only request was blocked, not silently tested').toEqual([]); });
    try { record.servedShaAfter = await baseline(request); }
    catch (error) { record.checks.build_identity = { status: 'failed', reason: String(error) }; }
    for (const name of catalogue.requiredChecks) if (!record.checks[name]) record.checks[name] = { status: 'unverified', reason: 'An earlier stage prevented this check; not success or not-applicable.' };
    for (const name of ['page_action', 'painted_text_overflow']) if (!record.checks[name]) record.checks[name] = { status: 'unverified', reason: 'Not reached; no success inferred.' };
    try { await capture(page, info, record, 'final.png'); } catch (error) { record.errors.push({ kind: 'capture', message: String(error) }); }
    record.network = { requests, blocked }; record.runtimeErrors = runtimeErrors;
    record.status = record.errors.length || catalogue.requiredChecks.some(name => ['failed', 'unverified'].includes(record.checks[name].status)) ? 'incomplete_or_failed' : 'common_contract_passed';
    const file = info.outputPath('audit-receipt.json'); fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, JSON.stringify(record, null, 2) + '\n');
    await info.attach('audit-receipt', { path: file, contentType: 'application/json' });
    console.log('FLUTTER_PAGE_AUDIT ' + JSON.stringify({ route: record.route, canonical: record.canonical, viewport: viewport.id, status: record.status, checks: Object.fromEntries(Object.entries(record.checks).map(([key, value]) => [key, { status: value.status, ...(value.status === 'failed' ? { reason: value.reason } : {}) }])) }));
  }
  expect(record.errors, 'capture, dialog, and audit harness errors cannot become a passed browser case').toEqual([]);
  expect(catalogue.requiredChecks.filter(name => ['failed', 'unverified'].includes(record.checks[name].status)), 'required failed/unverified checks stay visible as failures; optional unverified checks are separately aggregated').toEqual([]);
});
