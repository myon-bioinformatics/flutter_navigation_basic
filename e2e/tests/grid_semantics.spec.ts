import { test, expect, type Page, type Locator } from '@playwright/test';
import { waitForFlutter } from '../utils/helpers';
import { pressPoint } from '../utils/interaction.mjs';

// Regression for #183. The capture oracle in #220 is deliberately separate:
// these checks assert live Flutter semantics and a second *actual* drag, not PNGs.
test.describe.configure({ mode: 'parallel' });
test.setTimeout(60_000);

const item = (page: Page, label: string) =>
  page.locator(`[flt-semantics-identifier="interaction-item-${label}"]`);

type Rect = { x: number; y: number; width: number; height: number };

function gridDragPoint(box: Rect, intersection: Rect, viewport: { width: number; height: number }, yRatio: number) {
  if (![...Object.values(box), ...Object.values(intersection), viewport.width, viewport.height].every(Number.isFinite)
    || box.width < 48 || box.height < 48 || intersection.width < 48 || intersection.height < 48) {
    throw new Error('grid drag requires at least 48px of usable exposed target');
  }
  // Check actual edges, not an IntersectionObserver area ratio rounded below 1.
  if (box.x < 0 || box.y < 0 || box.x + box.width > viewport.width || box.y + box.height > viewport.height) {
    throw new Error('grid drag target extends outside the viewport');
  }
  const { x } = pressPoint(box, viewport);
  const y = Math.floor(box.y + box.height * yRatio);
  // Ancestor overflow can clip a target even when its bounds fit the viewport.
  // Require an interior integer input point with a 4px margin in the exposed
  // intersection. This is usable semantics-target evidence, not full-card paint.
  if (x < intersection.x + 4 || x > intersection.x + intersection.width - 4
    || y < intersection.y + 4 || y > intersection.y + intersection.height - 4) {
    throw new Error('grid drag point is clipped or too close to an exposed edge');
  }
  return { x, y };
}

async function measureExposedPoint(page: Page, target: Locator, yRatio: number) {
  await expect(target).toBeVisible();
  const measured = await target.evaluate(el => new Promise<{ box: Rect; intersection: Rect; ratio: number }>(resolve => {
    const rect = (r: DOMRectReadOnly): Rect => ({ x: r.x, y: r.y, width: r.width, height: r.height });
    const observer = new IntersectionObserver(([entry]) => {
      observer.disconnect();
      resolve({ box: rect(entry.boundingClientRect), intersection: rect(entry.intersectionRect), ratio: entry.intersectionRatio });
    });
    observer.observe(el);
  }));
  const viewport = page.viewportSize()!;
  return { ...gridDragPoint(measured.box, measured.intersection, viewport, yRatio), ...measured, viewport };
}

async function exposedPoint(page: Page, target: Locator, yRatio: number) {
  let point: Awaited<ReturnType<typeof measureExposedPoint>> | undefined;
  // Retain a bounded wait for Flutter layout after a resize or prior swap.
  // Retry the same strict geometry contract, never reduce its requirements.
  await expect(async () => { point = await measureExposedPoint(page, target, yRatio); })
    .toPass({ timeout: 5000, intervals: [100, 250, 500] });
  return point!;
}

async function assertGrid(page: Page, order: string[], visibleItems: string[] = ['A', 'B', 'C']) {
  await expect(page.getByText(`順序: ${order.join(', ')}`, { exact: true })).toBeVisible();
  for (const label of visibleItems) {
    const target = item(page, label);
    // A duplicated identifier is a regression even when the order label is correct.
    await expect(target).toHaveCount(1);
    await expect.poll(() => target.evaluate(el =>
      (el.textContent?.trim() || el.getAttribute('aria-label') || '').trim()
    ), { message: `semantics identity must display ${label}` }).toBe(label);
  }
}

async function swap(page: Page, from: string, to: string) {
  const a: Locator = item(page, from);
  const b: Locator = item(page, to);
  await expect(a).toHaveCount(1);
  await expect(b).toHaveCount(1);
  const start = await exposedPoint(page, a, 0.5);
  const end = await exposedPoint(page, b, 0.85);
  await test.info().attach(`grid-swap-${from}-to-${to}.json`, {
    body: JSON.stringify({ stage: 'prepared', input: 'mouse-drag', hold_ms: 700, from, to, start, end }, null, 2),
    contentType: 'application/json',
  });
  await page.mouse.move(start.x, start.y);
  await page.mouse.down();
  await page.waitForTimeout(700); // LongPressDraggable, emulated mouse not physical touch.
  await page.mouse.move(end.x, end.y, { steps: 20 });
  await page.mouse.up();
}

async function open(page: Page) {
  await page.goto('/#/screen173');
  await waitForFlutter(page, 30_000);
  await expect(page.getByText('順序: A, B, C', { exact: true })).toBeVisible();
}

test('screen173 semantics follow A/B/C through two grid swaps @portable', async ({ page }) => {
  await open(page);
  await assertGrid(page, ['A', 'B', 'C']);
  await swap(page, 'A', 'B');
  await assertGrid(page, ['B', 'A', 'C']);
  await swap(page, 'A', 'C');
  await assertGrid(page, ['B', 'C', 'A']);
});

test('grid drag geometry rejects viewport clipping and unusable targets @portable', () => {
  const viewport = { width: 1280, height: 720 };
  const box = { x: 12, y: 372.3333435058594, width: 628, height: 261.6666564941406 };
  expect(gridDragPoint(box, box, viewport, 0.85)).toEqual({ x: 326, y: 594 });
  for (const clipped of [{ ...box, x: -1 }, { ...box, y: -1 }, { ...box, x: 1000 }, { ...box, y: 600 }]) {
    expect(() => gridDragPoint(clipped, clipped, viewport, 0.85)).toThrow('outside the viewport');
  }
  for (const unusable of [{ ...box, width: 47 }, { ...box, height: 47 }, { ...box, x: NaN }]) {
    expect(() => gridDragPoint(unusable, unusable, viewport, 0.85)).toThrow('usable exposed target');
  }
  expect(() => gridDragPoint(box, { ...box, height: 50 }, viewport, 0.85)).toThrow('point is clipped');
});

test('grid drag point rejects clipping by a nested overflow ancestor @portable', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 320 });
  await page.setContent('<div id="clip" style="position:absolute;left:50px;top:50px;width:120px;height:120px;overflow:hidden"><div id="card" style="width:120px;height:120px">A</div></div>');
  const target = page.locator('#card');
  expect(await exposedPoint(page, target, 0.85)).toMatchObject({ x: 110, y: 152 });
  await page.locator('#clip').evaluate(el => { el.style.height = '60px'; });
  await expect(measureExposedPoint(page, target, 0.85)).rejects.toThrow('point is clipped');
});

test('screen173 short viewport keeps distinct A/B targets after repeated swaps @portable', async ({ page }) => {
  await open(page);
  await page.setViewportSize({ width: 390, height: 320 });
  // C can be clipped by the scroll viewport; don't mistake lazily exposed
  // semantics for missing data. Check A/B node identity and the full order label.
  await assertGrid(page, ['A', 'B', 'C'], ['A', 'B']);
  await swap(page, 'A', 'B');
  await assertGrid(page, ['B', 'A', 'C'], ['A', 'B']);
  await swap(page, 'B', 'A');
  await assertGrid(page, ['A', 'B', 'C'], ['A', 'B']);
});
