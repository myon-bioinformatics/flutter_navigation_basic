import { test, expect, type Page, type Locator } from '@playwright/test';
import { waitForFlutter } from '../utils/helpers';

// Regression for #183. The capture oracle in #220 is deliberately separate:
// these checks assert live Flutter semantics and a second *actual* drag, not PNGs.
test.describe.configure({ mode: 'parallel' });
test.setTimeout(60_000);

const item = (page: Page, label: string) =>
  page.locator(`[flt-semantics-identifier="interaction-item-${label}"]`);

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
  await expect(a).toBeInViewport({ ratio: 1 });
  await expect(b).toBeInViewport({ ratio: 1 });
  const start = (await a.boundingBox())!;
  const end = (await b.boundingBox())!;
  await page.mouse.move(start.x + start.width / 2, start.y + start.height / 2);
  await page.mouse.down();
  await page.waitForTimeout(700); // LongPressDraggable, emulated mouse not physical touch.
  await page.mouse.move(end.x + end.width / 2, end.y + end.height * 0.85, { steps: 20 });
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
