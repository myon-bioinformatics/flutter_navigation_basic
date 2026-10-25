'use strict';

const path = require('node:path');
const fs = require('node:fs');
const { createRequire } = require('node:module');
const { pathToFileURL } = require('node:url');
const fromE2E = createRequire(path.join(__dirname, '../../e2e/package.json'));
const { test, expect } = fromE2E('@playwright/test');
const playwrightVersion = fromE2E('@playwright/test/package.json').version;
const interaction = import(pathToFileURL(path.join(__dirname, '../../e2e/utils/interaction.mjs')).href);

// Deliberately immutable: a changed deployment is a stale baseline, not an
// invitation to update the reference or silently compare different revisions.
const REFERENCE_SHA = '9b38f3e935e9e171cbacc3af63f539ddce9db86b';
const REFERENCE_BASE = 'https://myon-bioinformatics.github.io/flutter_navigation_basic/';
const REFERENCE_URL = `${REFERENCE_BASE}#/examples/ui-showcase`;
const METADATA_URL = `${REFERENCE_BASE}assets/assets/diagnostics/build_metadata.json`;
const LOCAL_ORIGIN = 'http://127.0.0.1:8765';
const SUBTITLE = 'Standard Flutter widgets with external overrides and internal defaults.';
const HEADER_IDS = ['shared-header-title', 'shared-header-home', 'shared-header-favorite', 'shared-header-menu', 'shared-header-secondary'];
const CONTROL_IDS = ['shared-header-home', 'shared-header-favorite', 'shared-header-menu'];
const nativeNode = (page, id) => page.getByTestId(id);
const flutterNode = (page, id) => page.locator(`[flt-semantics-identifier="${id}"]`);
const node = (page, kind, id) => kind === 'native' ? nativeNode(page, id) : flutterNode(page, id);
const favorite = (page, kind) => kind === 'native'
  ? nativeNode(page, 'shared-header-favorite') : flutterNode(page, 'shared-header-favorite').getByRole('button');

function receipt(info, browser) {
  return {
    schema: 'ui-showcase-html-comparison/1', project: info.project.name,
    viewport: info.project.use.viewport, deviceScaleFactor: 1, locale: 'en-US', colorScheme: 'light',
    playwrightVersion, browserVersion: browser.version(), referenceSha: REFERENCE_SHA,
    candidateSha: process.env.CANDIDATE_SHA || null, workflowEventSha: process.env.GITHUB_SHA || null,
    runId: process.env.GITHUB_RUN_ID || null,
    pixelParityAsserted: false, status: 'incomplete', inputs: [], captures: [], observations: {},
  };
}

async function save(info, record) {
  record.testStatus = info.status;
  record.errors = info.errors.map(error => error.message);
  const file = info.outputPath('comparison.json');
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(record, null, 2) + '\n');
  await info.attach('comparison', { path: file, contentType: 'application/json' });
}

async function settle(page) {
  // Allow Flutter's 180ms route transition and pointer/scroll paint to complete.
  await page.waitForTimeout(300);
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
}

async function measureViewport(page, kind, record) {
  const actual = await page.evaluate(() => ({ width: innerWidth, height: innerHeight, deviceScaleFactor: devicePixelRatio }));
  record.observations[`${kind}Viewport`] = actual;
  expect.soft(actual, `${kind}: actual browser viewport and DPR`).toEqual({ ...page.viewportSize(), deviceScaleFactor: 1 });
}

async function capture(page, info, record, label) {
  const file = info.outputPath(`${label}.png`);
  const bytes = await page.screenshot({ path: file, timeout: 10_000 });
  record.captures.push({ file: `${label}.png`, bytes: bytes.length });
  await info.attach(label, { path: file, contentType: 'image/png' });
}

async function failureCapture(page, info, record, label) {
  if (!page || page.isClosed()) return;
  try { await capture(page, info, record, label); }
  catch (error) { record.captures.push({ file: `${label}.png`, error: String(error) }); }
}

async function openFlutter(page, record, reload = false) {
  if (reload) await page.reload();
  else await page.goto(REFERENCE_URL);
  await page.locator('flt-glass-pane').waitFor({ state: 'attached', timeout: 30_000 });
  // Reuse the existing semantics-ready contract, but not helpers.ts's synthetic
  // placeholder.click() loop. Only the accessibility bootstrap receives Enter;
  // no application state or DOM click dispatch is injected.
  if (await page.locator('flt-semantics').count() === 0) {
    const placeholder = page.locator('flt-semantics-placeholder[aria-label="Enable accessibility"]');
    await placeholder.waitFor({ state: 'attached', timeout: 15_000 });
    await placeholder.focus();
    await page.keyboard.press('Enter');
    record.inputs.push({ implementation: 'flutter', input: 'keyboard', key: 'Enter', purpose: 'enable accessibility once' });
  }
  await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: 30_000 });
  await expect(flutterNode(page, 'shared-header-title')).toContainText('UI Showcase');
  await expect(page.getByText(SUBTITLE, { exact: true })).toBeVisible();
  await settle(page);
}

async function readBaseline(request, record) {
  const response = await request.get(METADATA_URL, { headers: { 'Cache-Control': 'no-cache' }, timeout: 30_000 });
  record.baseline = { url: METADATA_URL, status: response.status(), body: await response.text() };
  expect(response.ok(), 'Published baseline metadata must be readable').toBe(true);
  const metadata = JSON.parse(record.baseline.body);
  record.baseline.metadata = metadata;
  delete record.baseline.body;
  const actual = metadata.repository?.revision?.sha;
  record.baseline.actualSha = actual ?? null;
  expect(actual, `STALE_BASELINE: expected ${REFERENCE_SHA}; served ${actual ?? 'no SHA'}. Explicit review is required; this suite never updates the baseline.`).toBe(REFERENCE_SHA);
}

async function headerGeometry(page, kind) {
  const boxes = {}, counts = {};
  for (const id of HEADER_IDS) {
    const target = node(page, kind, id);
    counts[id] = await target.count();
    boxes[id] = counts[id] === 1 ? await target.boundingBox() : null;
  }
  const hits = {}, hitTesting = {};
  for (const id of CONTROL_IDS) {
    const target = kind === 'native' ? node(page, kind, id) : node(page, kind, id).getByRole('button');
    hits[id] = await target.count() === 1 ? await target.boundingBox() : null;
    if (kind === 'native' && hits[id]) {
      hitTesting[id] = await target.evaluate(el => {
        const box = el.getBoundingClientRect();
        const hit = document.elementFromPoint(Math.floor(box.x + box.width / 2), Math.floor(box.y + box.height / 2));
        return !!hit && (el === hit || el.contains(hit));
      });
    }
  }
  const overflow = await page.evaluate(() => ({
    document: document.documentElement.scrollWidth > innerWidth + 1,
    body: document.body.scrollWidth > innerWidth + 1,
  }));
  return { boxes, counts, hits, hitTesting, overflow };
}

function checkHeader(geometry, viewport, label) {
  for (const id of HEADER_IDS) {
    expect.soft(geometry.counts[id], `${label}: unique ${id}`).toBe(1);
    const box = geometry.boxes[id];
    expect.soft(box, `${label}: visible ${id}`).not.toBeNull();
    if (!box) continue;
    expect.soft(box.width, `${label}: positive width ${id}`).toBeGreaterThan(0);
    expect.soft(box.height, `${label}: positive height ${id}`).toBeGreaterThan(0);
    expect.soft(box.x, `${label}: left ${id}`).toBeGreaterThanOrEqual(-1);
    expect.soft(box.y, `${label}: top ${id}`).toBeGreaterThanOrEqual(-1);
    expect.soft(box.x + box.width, `${label}: right ${id}`).toBeLessThanOrEqual(viewport.width + 1);
    expect.soft(box.y + box.height, `${label}: bottom ${id}`).toBeLessThanOrEqual(viewport.height + 1);
  }
  for (const id of CONTROL_IDS) {
    const box = geometry.hits[id];
    expect.soft(box, `${label}: hit target ${id}`).not.toBeNull();
    if (box) {
      expect.soft(box.width, `${label}: target width ${id}`).toBeGreaterThanOrEqual(39);
      expect.soft(box.height, `${label}: target height ${id}`).toBeGreaterThanOrEqual(39);
    }
  }
  const row = ['shared-header-title', ...CONTROL_IDS];
  for (let index = 1; index < row.length; index++) {
    const left = geometry.boxes[row[index - 1]], right = geometry.boxes[row[index]];
    if (left && right) expect.soft(left.x + left.width, `${label}: ${row[index - 1]} must not overlap ${row[index]}`).toBeLessThanOrEqual(right.x + 1);
  }
  expect.soft(geometry.overflow, `${label}: no horizontal page overflow`).toEqual({ document: false, body: false });
  for (const [id, self] of Object.entries(geometry.hitTesting)) {
    expect.soft(self, `${label}: ${id} owns its measured centre hit target`).toBe(true);
  }
}

function checkNativeRegions(regions, viewport) {
  const compact = viewport.width < 900;
  const body = regions['showcase-body-layout'].box;
  const overview = regions['showcase-overview-scroll'].box;
  const footer = regions['shared-footer'].box;
  compareBox(regions['shared-header-primary'].box, { x: 0, y: 0, width: viewport.width, height: 56 }, 'native primary header');
  compareBox(body, { x: 0, y: 104, width: viewport.width, height: viewport.height - 258 - (compact ? 80 : 0) }, 'native body viewport');
  for (const [id, box] of [['overview', overview], ['footer', footer]]) {
    expect.soft(box, `native ${id} region exists`).not.toBeNull();
    if (!box) continue;
    expect.soft(box.x, `native ${id} left`).toBeGreaterThanOrEqual(0);
    expect.soft(box.y, `native ${id} top`).toBeGreaterThanOrEqual(104);
    expect.soft(box.x + box.width, `native ${id} right`).toBeLessThanOrEqual(viewport.width + 1);
    expect.soft(box.y + box.height, `native ${id} bottom`).toBeLessThanOrEqual(viewport.height - 24 + 1);
  }
  if (body && footer) expect.soft(body.y + body.height, 'body does not overlap fixed footer').toBeLessThanOrEqual(footer.y + 1);
  expect.soft(regions['showcase-rail'].box === null, 'rail visibility matches compact breakpoint').toBe(compact);
  expect.soft(regions['showcase-bottom-navigation'].box === null, 'bottom navigation visibility matches compact breakpoint').toBe(!compact);
}

function compareBox(actual, expected, label) {
  expect.soft(actual, `${label}: candidate box exists`).not.toBeNull();
  expect.soft(expected, `${label}: reference box exists`).not.toBeNull();
  if (!actual || !expected) return;
  for (const key of ['x', 'y', 'width', 'height']) {
    expect.soft(Math.abs(actual[key] - expected[key]), `${label}.${key}: native ${actual[key]}, Flutter ${expected[key]}`).toBeLessThanOrEqual(1);
  }
}

async function checkFavorite(page, kind, selected) {
  const button = favorite(page, kind);
  const label = selected ? 'Remove favorite' : 'Favorite this page';
  if (kind === 'native') {
    await expect(button).toHaveAttribute('aria-label', label);
    await expect(button).toHaveAttribute('aria-pressed', String(selected));
  } else {
    // Tooltip ownership can extend the computed accessible name on Flutter.
    await expect(button).toHaveText(label);
    await expect(button).toHaveAttribute('aria-current', String(selected));
  }
}

async function pointerCycle(page, kind, info, record) {
  const button = favorite(page, kind);
  await expect(button).toBeEnabled();
  await checkFavorite(page, kind, false);
  const { press } = await interaction;
  for (const selected of [true, false]) {
    const input = await press(page, button, { touch: false });
    record.inputs.push({ implementation: kind, ...input });
    if (kind === 'native') expect.soft(input.hit.self, 'native favorite must own its real elementFromPoint hit target').toBe(true);
    await page.mouse.move(0, 0);
    await settle(page);
    if (selected) await capture(page, info, record, `${kind}-selected`);
    await checkFavorite(page, kind, selected);
  }
}

async function keyboardCycle(page, kind, info, record) {
  const button = favorite(page, kind);
  let tabs = 0;
  for (; tabs < 20;) {
    await page.keyboard.press('Tab');
    tabs++;
    if (await button.evaluate(el => el === document.activeElement || el.contains(document.activeElement))) break;
  }
  record.inputs.push({ implementation: kind, input: 'keyboard', key: 'Tab', presses: tabs, purpose: 'reach favorite without focus injection' });
  await expect(button, `${kind}: favorite must be keyboard reachable`).toBeFocused();
  for (const [key, selected] of [['Space', true], ['Enter', false]]) {
    await page.keyboard.press(key);
    record.inputs.push({ implementation: kind, input: 'keyboard', key });
    await checkFavorite(page, kind, selected);
    await expect(button, `${kind}: ${key} must retain favorite focus`).toBeFocused();
    if (key === 'Space') {
      await settle(page);
      await capture(page, info, record, `${kind}-keyboard-focused`);
      if (kind === 'native') {
        const focus = await button.evaluate(el => {
          const style = getComputedStyle(el);
          return { focusVisible: el.matches(':focus-visible'), outlineStyle: style.outlineStyle, outlineWidth: parseFloat(style.outlineWidth), outlineColor: style.outlineColor };
        });
        record.observations.nativeFocusRing = focus;
        expect.soft(focus.focusVisible, 'native keyboard focus must match :focus-visible').toBe(true);
        expect.soft(focus.outlineStyle, 'native keyboard focus outline must be visible').not.toBe('none');
        expect.soft(focus.outlineWidth, 'native keyboard focus outline must have nonzero width').toBeGreaterThan(0);
      }
    }
  }
}

async function contentWitness(page) {
  const title = page.getByText(SUBTITLE, { exact: true });
  const count = await title.count();
  return { count, box: count === 1 ? await title.boundingBox() : null };
}

async function scrollRegion(page, kind) {
  if (kind === 'native') return nativeNode(page, 'showcase-overview-scroll').evaluate(el => {
    const r = el.getBoundingClientRect();
    return { box: { x: r.x, y: r.y, width: r.width, height: r.height }, scrollTop: el.scrollTop, clientHeight: el.clientHeight, scrollHeight: el.scrollHeight };
  });
  return page.getByText(SUBTITLE, { exact: true }).evaluate(el => {
    const candidates = [];
    for (let parent = el.parentElement; parent; parent = parent.parentElement) {
      const rect = parent.getBoundingClientRect(), css = getComputedStyle(parent);
      if (parent.tagName === 'FLT-SEMANTICS' && ['auto', 'scroll'].includes(css.overflowY) && rect.width > 0 && rect.height > 0) {
        candidates.push({ box: { x: rect.x, y: rect.y, width: rect.width, height: rect.height }, scrollTop: parent.scrollTop, clientHeight: parent.clientHeight, scrollHeight: parent.scrollHeight });
      }
    }
    if (candidates.length === 1) return { ...candidates[0], identifiedBy: 'subtitle scroll ancestor' };
    // A fitted Flutter ListView may have no overflowing DOM ancestor. Its
    // semantics body still starts immediately under the 104px shared header.
    const bodies = [];
    for (let parent = el.parentElement; parent; parent = parent.parentElement) {
      const rect = parent.getBoundingClientRect();
      if (parent.tagName === 'FLT-SEMANTICS' && Math.abs(rect.y - 104) <= 1 && rect.height > 0 && rect.height < innerHeight - 104) {
        const box = { x: rect.x, y: rect.y, width: rect.width, height: rect.height };
        if (!bodies.some(item => JSON.stringify(item.box) === JSON.stringify(box))) bodies.push({ box });
      }
    }
    if (candidates.length > 1 || bodies.length !== 1) throw new Error(`Ambiguous Flutter overview region: ${candidates.length} scroll ancestors, ${bodies.length} body bounds`);
    return { ...bodies[0], identifiedBy: 'unique subtitle ancestor body bounds', scrollTop: null, clientHeight: null, scrollHeight: null };
  });
}

async function wheelProof(page, kind, info, record) {
  const header = node(page, kind, 'shared-header-title');
  const footer = kind === 'native' ? nativeNode(page, 'shared-footer') : flutterNode(page, 'tool-door-dropdown');
  const region = await scrollRegion(page, kind);
  const before = { region, content: await contentWitness(page), header: await header.boundingBox(), footer: await footer.boundingBox() };
  const x = Math.floor(region.box.x + Math.min(12, region.box.width / 2));
  const y = Math.floor(region.box.y + region.box.height / 2);
  await page.mouse.move(x, y);
  await page.mouse.wheel(0, 240);
  record.inputs.push({ implementation: kind, input: 'mouse-wheel', x, y, deltaY: 240 });
  await settle(page);
  const after = { content: await contentWitness(page), header: await header.boundingBox(), footer: await footer.boundingBox() };
  if (kind === 'native') after.region = await scrollRegion(page, kind);
  record.observations[`${kind}Scroll`] = { before, after, requiredMovement: page.viewportSize().width < 900 };
  // Capture before assertions, including a failed/no-op wheel gesture.
  await capture(page, info, record, `${kind}-scrolled`);
  if (page.viewportSize().width < 900) {
    expect.soft(after.content, `${kind}: compact body content must move after real wheel input`).not.toEqual(before.content);
    if (kind === 'native') expect.soft(after.region.scrollTop, 'native compact body scrollTop must increase').toBeGreaterThan(before.region.scrollTop);
  }
  compareBox(after.header, before.header, `${kind}: fixed header during body scroll`);
  compareBox(after.footer, before.footer, `${kind}: fixed footer during body scroll`);
  if (page.viewportSize().width < 900) {
    // Flutter merges this card's heading and paragraph into one semantics text
    // node. Native HTML deliberately retains its separate heading element.
    const last = kind === 'native'
      ? page.getByRole('heading', { name: 'Low coupling', exact: true })
      : page.getByText(/^Low coupling\s+This showcase uses Flutter\/Dart SDK APIs only; no UI, state-management, media, or config package is required\.$/);
    let finalCard;
    for (let attempt = 0; attempt <= 6; attempt++) {
      const count = await last.count();
      const box = count === 1 ? await last.boundingBox() : null;
      const intersection = box ? {
        width: Math.max(0, Math.min(box.x + box.width, region.box.x + region.box.width) - Math.max(box.x, region.box.x)),
        height: Math.max(0, Math.min(box.y + box.height, region.box.y + region.box.height) - Math.max(box.y, region.box.y)),
      } : { width: 0, height: 0 };
      finalCard = { count, box, intersection, extraWheelInputs: attempt };
      if (intersection.height >= 12 && intersection.width >= 30) break;
      if (attempt === 6) break;
      await page.mouse.wheel(0, 180);
      record.inputs.push({ implementation: kind, input: 'mouse-wheel', x, y, deltaY: 180, purpose: 'reach final card' });
      await settle(page);
    }
    record.observations[`${kind}FinalCard`] = finalCard;
    await capture(page, info, record, `${kind}-last-card`);
    expect.soft(finalCard.count, `${kind}: final-card title is unique`).toBe(1);
    expect.soft(finalCard.intersection.height, `${kind}: final-card title has a usable visible segment inside the body, not merely an unclipped DOM box`).toBeGreaterThanOrEqual(12);
    expect.soft(finalCard.intersection.width, `${kind}: final-card title intersects body horizontally`).toBeGreaterThanOrEqual(30);
    compareBox(await header.boundingBox(), before.header, `${kind}: header stays fixed through final-card reach`);
    compareBox(await footer.boundingBox(), before.footer, `${kind}: footer stays fixed through final-card reach`);
  }
}

async function nativeKeyboardScroll(page, info, record) {
  if (page.viewportSize().width >= 900) return;
  // Reach the scroll region through ordinary keyboard traversal, not
  // element.focus. Home below defeats browser-restored scroll position.
  await page.reload();
  await checkFavorite(page, 'native', false);
  const button = favorite(page, 'native');
  let tabs = 0;
  for (; tabs < 8;) {
    await page.keyboard.press('Tab');
    tabs++;
    if (await button.evaluate(el => el === document.activeElement)) break;
  }
  await expect(button).toBeFocused();
  await page.keyboard.press('Tab');
  const main = nativeNode(page, 'showcase-overview-scroll');
  await expect(main, 'Tab after favorite must reach the native scroll region').toBeFocused();
  record.inputs.push({ implementation: 'native', input: 'keyboard', key: 'Tab', presses: tabs + 1, purpose: 'reach body via favorite' });
  await page.keyboard.press('Home');
  record.inputs.push({ implementation: 'native', input: 'keyboard', key: 'Home', purpose: 'establish body scroll start without DOM mutation' });
  await expect.poll(() => main.evaluate(el => el.scrollTop), { message: 'Home must restore the focused native body to its start' }).toBeLessThanOrEqual(1);
  const header = nativeNode(page, 'shared-header-title'), footer = nativeNode(page, 'shared-footer');
  const before = { region: await scrollRegion(page, 'native'), header: await header.boundingBox(), footer: await footer.boundingBox() };
  await page.keyboard.press('PageDown');
  record.inputs.push({ implementation: 'native', input: 'keyboard', key: 'PageDown', purpose: 'native-only body scrolling' });
  await settle(page);
  const after = { region: await scrollRegion(page, 'native'), header: await header.boundingBox(), footer: await footer.boundingBox() };
  record.observations.nativeKeyboardScroll = { before, after, flutterParityAsserted: false };
  await capture(page, info, record, 'native-keyboard-scrolled');
  expect.soft(after.region.scrollTop, 'PageDown must move the focused native body').toBeGreaterThan(before.region.scrollTop);
  await expect(main, 'native body must retain focus after PageDown').toBeFocused();
  compareBox(after.header, before.header, 'native header during keyboard body scroll');
  compareBox(after.footer, before.footer, 'native footer during keyboard body scroll');
}

test('native HTML owns layout, real input, session reset, and local-only runtime', async ({ page, browser }, info) => {
  const record = receipt(info, browser);
  const requests = [], blocked = [], errors = [];
  page.on('request', request => requests.push(request.url()));
  page.on('pageerror', error => errors.push(error.message));
  await page.route('**/*', route => {
    if (new URL(route.request().url()).origin === LOCAL_ORIGIN) return route.continue();
    blocked.push(route.request().url());
    return route.abort('blockedbyclient');
  });
  try {
    await page.goto('/');
    await settle(page);
    await measureViewport(page, 'native', record);
    await capture(page, info, record, 'native-before');
    const geometry = await headerGeometry(page, 'native');
    record.observations.nativeHeader = geometry;
    checkHeader(geometry, page.viewportSize(), 'native');
    for (const id of ['shared-header-primary', 'showcase-body-layout', 'showcase-overview-scroll', 'shared-footer', 'showcase-bottom-navigation', 'showcase-rail']) {
      const target = nativeNode(page, id);
      record.observations[id] = { count: await target.count(), box: await target.boundingBox() };
      expect.soft(await target.count(), `unique native ${id}`).toBe(1);
    }
    checkNativeRegions(record.observations, page.viewportSize());
    await pointerCycle(page, 'native', info, record);
    await keyboardCycle(page, 'native', info, record);
    // Reload while selected, not after resetting to false, to prove ephemerality.
    await page.keyboard.press('Space');
    await checkFavorite(page, 'native', true);
    await page.reload();
    await checkFavorite(page, 'native', false);
    record.observations.nativeReloadReset = true;
    await wheelProof(page, 'native', info, record);
    await nativeKeyboardScroll(page, info, record);
    const runtime = await page.evaluate(() => ({
      scripts: [...document.scripts].map(script => script.src),
      flutterElements: document.querySelectorAll('flt-glass-pane, flutter-view, flt-semantics').length,
      resourceURLs: performance.getEntriesByType('resource').map(item => item.name),
      overviewOverflowX: document.querySelector('[data-testid="showcase-overview-scroll"]').scrollWidth > document.querySelector('[data-testid="showcase-overview-scroll"]').clientWidth + 1,
    }));
    record.observations.runtime = runtime;
    expect.soft(runtime.scripts.map(url => new URL(url).pathname).sort()).toEqual(['/app.js', '/state.js']);
    expect.soft(runtime.flutterElements).toBe(0);
    expect.soft(runtime.overviewOverflowX, 'native body must not overflow horizontally').toBe(false);
    expect.soft(requests.some(url => /flutter_bootstrap|main\.dart|canvaskit|\.wasm(?:$|\?)/i.test(url)), 'native runtime must not request Flutter/Dart/CanvasKit').toBe(false);
    expect.soft(blocked, 'native runtime must not attempt external network requests').toEqual([]);
    expect.soft(errors, 'native runtime must not raise browser errors').toEqual([]);
    const otherControls = page.locator('button:not([data-testid="shared-header-favorite"]), select');
    expect.soft(await otherControls.evaluateAll(elements => elements.every(el => el.disabled)), 'out-of-scope fixture controls remain disabled').toBe(true);
    record.status = info.errors.length ? 'failed' : 'complete';
  } catch (error) {
    record.status = 'failed';
    record.failure = String(error);
    throw error;
  } finally {
    record.network = { requests, blocked, errors };
    await failureCapture(page, info, record, 'native-final');
    await save(info, record);
  }
});

test('pinned published Flutter and native header bounds share the same viewport contract', async ({ page, context, browser, request }, info) => {
  const record = receipt(info, browser);
  let flutter;
  try {
    await page.goto('/');
    await settle(page);
    await measureViewport(page, 'native', record);
    await capture(page, info, record, 'native-comparison-before');
    await readBaseline(request, record);
    flutter = await context.newPage();
    await openFlutter(flutter, record);
    await measureViewport(flutter, 'flutter', record);
    await capture(flutter, info, record, 'flutter-before');
    const candidate = await headerGeometry(page, 'native');
    const reference = await headerGeometry(flutter, 'flutter');
    record.observations.nativeHeader = candidate;
    record.observations.flutterHeader = reference;
    checkHeader(candidate, page.viewportSize(), 'native');
    checkHeader(reference, flutter.viewportSize(), 'Flutter');
    for (const id of HEADER_IDS) compareBox(candidate.boxes[id], reference.boxes[id], id);
    for (const id of CONTROL_IDS) compareBox(candidate.hits[id], reference.hits[id], `${id} hit target`);
    record.observations.nativeBody = await scrollRegion(page, 'native');
    record.observations.flutterBody = await scrollRegion(flutter, 'flutter');
    compareBox(record.observations.nativeBody.box, record.observations.flutterBody.box, 'overview viewport bounds');
    // Content typography is deliberately not a pixel-parity or line-wrap oracle.
    await pointerCycle(flutter, 'flutter', info, record);
    await keyboardCycle(flutter, 'flutter', info, record);
    await flutter.keyboard.press('Space');
    await checkFavorite(flutter, 'flutter', true);
    await openFlutter(flutter, record, true);
    await checkFavorite(flutter, 'flutter', false);
    record.observations.flutterReloadReset = true;
    await wheelProof(flutter, 'flutter', info, record);
    // Detect a deployment that moved while this comparison was running too.
    await readBaseline(request, record);
    record.status = info.errors.length ? 'failed' : 'complete';
  } catch (error) {
    record.status = 'failed';
    record.failure = String(error);
    throw error;
  } finally {
    await failureCapture(flutter, info, record, 'flutter-final');
    await save(info, record);
    if (flutter) await flutter.close();
  }
});
