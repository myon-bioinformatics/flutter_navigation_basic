import { test, expect, type Page, type Locator, type TestInfo } from '@playwright/test';
import { writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { waitForFlutter } from '../utils/helpers';
import { press } from '../utils/interaction.mjs';

// #183: observe deliberate layout exceptions without requiring a footer where
// none exists. A new Door is a product change, not deduplication of these bodies.
test.describe.configure({ mode: 'parallel' });
test.setTimeout(90_000);

const node = (page: Page, id: string) => page.locator(`[flt-semantics-identifier="${id}"]`);
async function settle(page: Page) {
  // Semantics precede Flutter's painted route/AnimatedList transitions.
  await page.waitForTimeout(650);
  await page.evaluate(() => new Promise<void>(resolve => requestAnimationFrame(() => requestAnimationFrame(() => resolve()))));
}

async function open(page: Page, route: string) {
  await page.goto(process.env.FLUTTER_WEB_BASE_URL
    ? new URL(`#${route}`, process.env.FLUTTER_WEB_BASE_URL).href : `/#${route}`);
  await waitForFlutter(page, 30_000);
  await expect(node(page, 'shared-header-title')).toBeVisible();
  await settle(page);
}

async function header(page: Page, route: string, info: TestInfo, file: string) {
  const boxes: Record<string, Awaited<ReturnType<Locator['boundingBox']>>> = {};
  for (const id of ['shared-header-title', 'shared-header-home', 'shared-header-favorite', 'shared-header-menu']) {
    await expect(node(page, id)).toHaveCount(1);
    await expect(node(page, id)).toBeInViewport({ ratio: 1 });
    boxes[id] = await node(page, id).boundingBox();
  }
  const snapshot = { schemaVersion: 1, route, requiresSecondary: false,
    title: await node(page, 'shared-header-title').innerText(), viewport: page.viewportSize(), boxes };
  const path = info.outputPath(file);
  writeFileSync(path, JSON.stringify(snapshot, null, 2));
  const oracle = spawnSync('python3', ['-S', '../python/header_contracts.py', path], { encoding: 'utf8' });
  expect(oracle.error).toBeUndefined();
  expect(oracle.status, oracle.stdout + oracle.stderr).toBe(0);
  await info.attach(file, { path, contentType: 'application/json' });
  return snapshot;
}

async function capture(page: Page, info: TestInfo, file: string) {
  await settle(page);
  const path = info.outputPath(file);
  const png = await page.screenshot({ path });
  await info.attach(file, { path, contentType: 'image/png' });
  return { file, bytes: png.length, sha256: createHash('sha256').update(png).digest('hex') };
}

async function captureGesturePaint(page: Page, info: TestInfo, receipt: Record<string, any>) {
  const proof = receipt.gesture_paint;
  // Keep the ordinary post-release capture, even if it is stale. Moving the
  // released mouse is an explicit additional input, NOT proof that mouseup alone
  // painted correctly on WebKit mobile emulation (see #183).
  receipt.captures.push(await capture(page, info, 'exception-short-after-release.png'));
  const park = { input: 'mouse-move', x: 0, y: 0, buttons: 0,
    reason: 'post-release-paint-synchronization', target: 'noninteractive-page-corner' };
  await page.mouse.move(park.x, park.y);
  receipt.inputs.push(park);
  await expect(node(page, 'interaction-order')).toHaveText('順序: B, A, C');
  await settle(page);
  const file = 'exception-short-after-action.png';
  const path = info.outputPath(file);
  const geometryPath = info.outputPath('gesture-paint-geometry.json');
  writeFileSync(geometryPath, JSON.stringify(proof.geometry, null, 2));
  await info.attach('gesture-paint-geometry.json', { path: geometryPath, contentType: 'application/json' });
  let previousHash: string | undefined;
  let captured: { file: string; bytes: number; sha256: string } | undefined;
  proof.status = 'failed';
  proof.attempts = [];
  try {
    await expect.poll(async () => {
      const png = await page.screenshot({ path });
      captured = { file, bytes: png.length, sha256: createHash('sha256').update(png).digest('hex') };
      const oracle = spawnSync('python3', ['-S', '../python/gesture_paint.py',
        info.outputPath(proof.before.file), path, geometryPath], { encoding: 'utf8' });
      if (oracle.error || ![0, 1].includes(oracle.status!)) {
        throw new Error(`Gesture paint oracle failed: ${oracle.error ?? oracle.stdout + oracle.stderr}`);
      }
      const pixels = JSON.parse(oracle.stdout);
      const stable = previousHash === captured.sha256;
      proof.attempts.push({ ...captured, stable, ...pixels });
      previousHash = captured.sha256;
      // Two identical frames alone can both be stale. Check the actual PNG's
      // swapped card pixels against the distinct pre-drag cards from this run.
      return stable && pixels.matches;
    }, { timeout: 10_000, intervals: [100, 250, 500],
      message: 'stable PNG must contain the same-run B/A card pixel permutation' }).toBe(true);
    proof.status = 'verified';
    return captured!;
  } finally {
    if (captured) {
      proof.capture = captured;
      await info.attach(file, { path, contentType: 'image/png' });
    }
  }
}

async function drag(page: Page, from: Locator, to: Locator, hold = 0) {
  await expect(from).toBeInViewport({ ratio: 1 });
  await expect(to).toBeInViewport({ ratio: 1 });
  const a = (await from.boundingBox())!, b = (await to.boundingBox())!;
  const start = { x: Math.floor(a.x + a.width / 2), y: Math.floor(a.y + a.height / 2) };
  const end = { x: Math.floor(b.x + b.width / 2), y: Math.floor(b.y + b.height * 0.85) };
  await page.mouse.move(start.x, start.y);
  await page.mouse.down();
  if (hold) await page.waitForTimeout(hold);
  await page.mouse.move(end.x, end.y, { steps: 20 });
  await page.mouse.up();
  return { input: 'mouse-drag', start, end, hold_ms: hold, from: a, to: b };
}

// Mobile WebKit cannot emit Playwright wheel input. Drive the accessibility
// scroll region until a useful visible segment exists, including lazy children.
// This remains semantics-scroll evidence, not native touch-swipe evidence.
async function revealBySemantics(page: Page, target: Locator, minimumHeight: number, inputs: unknown[]) {
  if (await target.count()) {
    await target.scrollIntoViewIfNeeded();
    await settle(page);
  }
  for (let attempt = 0; attempt < 12; attempt++) {
    const box = await target.count() ? await target.boundingBox() : null;
    if (box && box.height >= minimumHeight - 0.5 && box.y >= 56 && box.y + box.height <= 320) return;
    const delta = box && box.y < 56 ? -120 : 120;
    const regions = await page.locator('flt-semantics').evaluateAll((elements, delta) => {
      const regions = elements.filter(el => getComputedStyle(el).overflowY === 'scroll'
        && el.clientHeight > 0 && el.clientWidth > innerWidth / 2);
      for (const el of regions) el.scrollTop += delta;
      return regions.length;
    }, delta);
    inputs.push({ input: 'semantics-scroll-region', regions, delta_y: delta, before: box,
      minimum_visible_height: minimumHeight, reason: 'mobile-webkit-wheel-unsupported' });
    expect(regions).toBeGreaterThan(0);
    await settle(page);
  }
  throw new Error(`Semantics scrolling did not expose ${minimumHeight}px of the target`);
}

for (const id of [136, 137, 171, 173, 174, 183, 91, 109]) {
  test(`exceptional chrome /screen${id} retains controls in a short viewport @portable`, id === 91 || id === 109 ? { lock: 'system-clipboard' } : {}, async ({ page }, info) => {
    const route = `/screen${id}`;
    const receipt: Record<string, any> = { schema: 'flutter-chrome-audit/1', stage: 'failed', route, project: info.project.name,
      browser_version: page.context().browser()!.version(), ci_sha: process.env.GITHUB_SHA ?? null,
      expected_sha: process.env.EXPECTED_SHA ?? null,
      run_id: process.env.GITHUB_RUN_ID ?? null, captures: [], inputs: [] };
    try {
      // Compare within the same browser/profile, never across platform pixels.
      await open(page, '/screen6');
      const standard = await header(page, '/screen6', info, 'standard-header.json');
      receipt.standard = { ...standard, door: await node(page, 'tool-door-dropdown').boundingBox() };
      receipt.captures.push(await capture(page, info, 'standard.png'));
      const viewport = page.viewportSize()!;
      await page.setViewportSize({ width: viewport.width, height: 320 });
      await settle(page);
      const standardShort = await header(page, '/screen6', info, 'standard-short-header.json');
      await expect(node(page, 'tool-door-dropdown')).toBeInViewport({ ratio: 1 });
      receipt.standard_short = { ...standardShort, door: await node(page, 'tool-door-dropdown').boundingBox() };
      receipt.captures.push(await capture(page, info, 'standard-short.png'));
      await page.setViewportSize(viewport);
      await open(page, route);
      const specialized = await header(page, route, info, 'exception-header.json');
      expect(specialized.title).toContain(`Pattern ${id < 100 ? '0' : ''}${id}`);
      for (const key of ['shared-header-home', 'shared-header-favorite', 'shared-header-menu']) {
        expect(specialized.boxes[key]).toEqual(standard.boxes[key]);
      }
      receipt.initial = specialized;
      // Record absence separately from navigation success; do not freeze it as
      // a required defect or make the test fail when a future Door is approved.
      receipt.door_count = await node(page, 'tool-door-dropdown').count();
      receipt.captures.push(await capture(page, info, 'exception-initial.png'));
      await page.setViewportSize({ width: viewport.width, height: 320 });
      await settle(page);
      receipt.short = await header(page, route, info, 'short-header.json');
      for (const key of ['shared-header-home', 'shared-header-favorite', 'shared-header-menu']) {
        expect(receipt.short.boxes[key]).toEqual(standardShort.boxes[key]);
      }
      const touch = !!info.project.use.hasTouch;
      if (id === 136 || id === 137) {
        const run = page.getByRole('button', { name: '実行', exact: true });
        await expect(run).toBeInViewport({ ratio: 1 });
        receipt.inputs.push(await press(page, run, { touch }));
        await expect(page.getByText(/55/)).toBeVisible();
        // Web fallback and compute completion are observable, but a transient
        // running frame/native Isolate scheduling are covered by Widget tests.
        await expect(run).toBeEnabled();
        receipt.result = await page.getByText(/55/).innerText();
      } else if (id === 171 || id === 173) {
        if (info.project.name === 'mobile-webkit') {
          // DPR=3 preserves equal pixel phase when these equal-size cards swap.
          // This is a focused oracle for #183, not a cross-device pixel baseline.
          receipt.gesture_paint = { method: 'same-run-card-permutation/1',
            before: await capture(page, info, 'exception-short-before-action.png'),
            geometry: { viewport: page.viewportSize(),
              device_scale_factor: await page.evaluate(() => devicePixelRatio),
              slots: [await node(page, 'interaction-item-A').boundingBox(),
                await node(page, 'interaction-item-B').boundingBox()] } };
          receipt.captures.push(receipt.gesture_paint.before);
        }
        // Desktop mouse on every emulated profile; this is NOT touch-drag proof.
        receipt.inputs.push(await drag(page, node(page, 'interaction-item-A'),
          node(page, 'interaction-item-B'), id === 173 ? 700 : 0));
        if (id === 173) await expect(page.getByText('順序: B, A, C')).toBeVisible();
        else await expect(page.getByText('順序: A, B, C')).toHaveCount(0);
        receipt.result = await node(page, 'interaction-order').innerText();
      } else if (id === 174) {
        receipt.inputs.push(await press(page, page.getByRole('button', { name: '挿入', exact: true }), { touch }));
        await expect(page.getByText('順序: N1, A, B, C')).toBeVisible();
        await expect(node(page, 'interaction-item-N1')).toBeInViewport({ ratio: 1 });
        receipt.result = await node(page, 'interaction-order').innerText();
      } else if (id === 183) {
        receipt.inputs.push(await press(page, node(page, 'interaction-select-A'), { touch }));
        await expect(page.getByText('選択数: 1')).toBeVisible();
        receipt.inputs.push(await press(page, page.getByRole('button', { name: '選択項目を削除', exact: true }), { touch }));
        await expect(page.getByText('順序: B, C')).toBeVisible();
        receipt.result = await node(page, 'interaction-order').innerText();
      } else {
        const last = page.getByRole('button', { name: '利用方法・制約 のURLをコピー', exact: true });
        receipt.last_copy_before = await last.count() ? await last.boundingBox() : null;
        if (info.project.name === 'mobile-webkit') {
          await revealBySemantics(page, last, 40, receipt.inputs);
        } else {
          // Wheel over the ListView padding, outside SelectableText's own
          // editable/scrollable region. Some last tiles are built lazily.
          await page.mouse.move(8, 180);
          for (let attempt = 0; attempt < 12; attempt++) {
            await page.mouse.wheel(0, 240);
            await settle(page);
            const box = await last.count() ? await last.boundingBox() : null;
            receipt.inputs.push({ input: 'wheel', x: 8, y: 180, delta_y: 240, after: box });
            if (box && box.height >= 40 && box.y >= 56 && box.y + box.height <= 320) break;
          }
        }
        await settle(page);
        await expect(last).toBeInViewport({ ratio: 1 });
        receipt.last_copy_after = await last.boundingBox();
        expect(receipt.last_copy_after!.height).toBeGreaterThanOrEqual(39.5);
        receipt.result = 'last source copy control reachable';
        if (info.project.name.includes('chromium')) {
          await page.context().grantPermissions(['clipboard-read', 'clipboard-write']);
          await page.evaluate(() => navigator.clipboard.writeText('chrome audit sentinel'));
          receipt.inputs.push(await press(page, last, { touch }));
          const expectedPath = `docs/data-processing-${id === 91 ? 'validation-091-099' : 'conversion-103-110'}.md`;
          await expect.poll(() => page.evaluate(() => navigator.clipboard.readText())).not.toBe('chrome audit sentinel');
          const copied = await page.evaluate(() => navigator.clipboard.readText());
          const url = new URL(copied);
          expect(url.origin).toBe('https://github.com');
          expect(url.pathname).toMatch(/^\/myon-bioinformatics\/flutter_navigation_basic\/blob\/[^/]+\//);
          expect(url.pathname.endsWith('/' + expectedPath)).toBe(true);
          receipt.clipboard = copied;
        } else {
          receipt.clipboard = 'not tested: Chromium permissions required; geometry only';
        }
      }
      receipt.captures.push(receipt.gesture_paint
        ? await captureGesturePaint(page, info, receipt)
        : await capture(page, info, 'exception-short-after-action.png'));
      if ([171, 173, 174, 183].includes(id)) {
        const last = node(page, 'interaction-item-C');
        // Selection uses CheckboxListTile identifiers instead of item cards.
        const target = id === 183 ? node(page, 'interaction-select-C') : last;
        receipt.last_item_before = await target.count() ? await target.boundingBox() : null;
        // Flutter clips semantics boxes to their scroll region: a 6px sliver
        // can satisfy toBeInViewport(1). Require a usable visible segment too.
        // Grid cells can be taller than the entire short body, so record their
        // partial extent explicitly rather than claiming the whole cell fits.
        const minimumHeight = 48;
        if (info.project.name === 'mobile-webkit') {
          await revealBySemantics(page, target, minimumHeight, receipt.inputs);
        } else {
          await page.mouse.move(20, 250);
          for (let attempt = 0; attempt < 8; attempt++) {
            await page.mouse.wheel(0, 120);
            await settle(page);
            const box = await target.count() ? await target.boundingBox() : null;
            receipt.inputs.push({ input: 'wheel', target: 'last-item', x: 20, y: 250, delta_y: 120, after: box });
            if (box && box.height >= minimumHeight && box.y >= 56 && box.y + box.height <= 320) break;
          }
        }
        await settle(page);
        await expect(target).toBeInViewport({ ratio: 1 });
        receipt.last_item_after = await target.boundingBox();
        expect(receipt.last_item_after!.height).toBeGreaterThanOrEqual(minimumHeight - 0.5);
        receipt.captures.push(await capture(page, info, 'exception-short-after-scroll.png'));
      }
      // A footer-less screen can still leave via the shared header. Exercise
      // actual navigation instead of claiming onward Door success from a URL.
      receipt.inputs.push(await press(page, node(page, 'shared-header-home').getByRole('button'), { touch }));
      const dialog = page.getByRole('alertdialog');
      await expect(dialog).toBeVisible();
      receipt.inputs.push(await press(page, dialog.getByRole('button', { name: 'Home', exact: true }), { touch }));
      await expect(node(page, 'shared-header-title')).toContainText('🏠');
      await expect(dialog).toHaveCount(0);
      receipt.stage = 'complete';
    } finally {
      const output = info.outputPath('chrome-audit.json');
      writeFileSync(output, JSON.stringify(receipt, null, 2));
      await info.attach('chrome-audit.json', { path: output, contentType: 'application/json' });
    }
  });
}
