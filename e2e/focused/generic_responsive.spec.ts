import { test, expect, type Page, type Locator, type TestInfo } from '@playwright/test';
import { navigateToScreen } from '../utils/helpers';

const layouts = [3, 21, 39, 57, 75, 100, 111, 129, 147, 165, 185];
const body = (page: Page) => page.locator('[flt-semantics-identifier="generic-body"]');
const template = body; // Source-unique controls below metadata; no test-only app boundary.
const delay = async (page: Page) => {
  await page.waitForTimeout(600);
  await page.evaluate(() => new Promise<void>(r => requestAnimationFrame(() => requestAnimationFrame(() => r()))));
};

// Fully visible in every clipping ancestor and the body viewport, not merely
// a nonzero semantic rectangle. Reading geometry never scrolls or focuses DOM.
async function geometry(page: Page, target: Locator) {
  const outer = await body(page).boundingBox();
  return target.evaluate((el, envelope) => {
    if (!envelope) throw Error('Missing body viewport');
    const b = el.getBoundingClientRect();
    let left = Math.max(0, envelope.x), top = Math.max(0, envelope.y);
    let right = Math.min(innerWidth, envelope.x + envelope.width), bottom = Math.min(innerHeight, envelope.y + envelope.height);
    for (let p: Element | null = el; p; p = p.parentElement) {
      const c = getComputedStyle(p), r = p.getBoundingClientRect();
      if (c.clipPath !== 'none' || c.display === 'none' || c.visibility === 'hidden') return { visible: false, box: b.toJSON() };
      if (/(auto|scroll|hidden|clip)/.test(c.overflowX)) { left = Math.max(left, r.left); right = Math.min(right, r.right); }
      if (/(auto|scroll|hidden|clip)/.test(c.overflowY)) { top = Math.max(top, r.top); bottom = Math.min(bottom, r.bottom); }
    }
    return { visible: b.width > 0 && b.height > 0 && b.left >= left - 1 && b.right <= right + 1 && b.top >= top - 1 && b.bottom <= bottom + 1,
      box: { x: b.x, y: b.y, width: b.width, height: b.height }, clip: { left, top, right, bottom } };
  }, outer);
}
async function reveal(page: Page, target: Locator, inputs: unknown[]) {
  for (let attempt = 0; attempt < 9; attempt++) {
    const count = await target.count();
    expect(count, 'source control must not be ambiguous').toBeLessThanOrEqual(1);
    const observed = count === 1 ? await geometry(page, target) : null;
    if (observed?.visible) return observed;
    const box = await body(page).boundingBox();
    if (!box || box.height <= 0) throw Error('No usable body viewport');
    // Left edge selects the outer wrapper rather than a nested template list.
    const x = Math.floor(box.x + 3), y = Math.floor(box.y + Math.min(24, box.height / 2));
    const deltaY = observed && observed.box.y < box.y ? -120 : 120;
    await page.mouse.move(x, y); await page.mouse.wheel(0, deltaY);
    inputs.push({ kind: 'wheel', x, y, deltaY }); await delay(page);
  }
  throw Error('Control not fully reachable after bounded real wheel input');
}
async function clickMeasured(page: Page, target: Locator, inputs: unknown[]) {
  const g = await reveal(page, target, inputs); await delay(page);
  const again = await geometry(page, target); expect(again.visible).toBe(true);
  expect(Math.abs(again.box.y - g.box.y)).toBeLessThanOrEqual(1);
  const x = Math.floor(again.box.x + again.box.width / 2), y = Math.floor(again.box.y + again.box.height / 2);
  await page.mouse.click(x, y); inputs.push({ kind: 'mouse', x, y });
}
async function focusByTab(page: Page, input: Locator) {
  for (let i = 0; i < 30; i++) {
    if (await input.evaluate(el => el === document.activeElement)) return;
    await page.keyboard.press('Tab');
  }
  throw Error('Input not reachable with bounded real Tab sequence');
}
function mergedLeaf(scope: Locator, label: string) {
  const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return scope.locator('flt-semantics:not(:has(flt-semantics))').filter({ hasText: new RegExp('^' + escaped + '$') });
}
function targets(page: Page, id: number): Locator[] {
  const scope = template(page);
  switch (id) {
    case 3: return [mergedLeaf(scope, '1\nBasicReplace item 1\nNavigation: BasicReplace, API: HttpPut, Theme: TextButton, Data: FilterNested')];
    case 21: return [scope.getByText('Screen ID: 21', { exact: true })];
    case 39: return [scope.getByRole('textbox'), scope.getByRole('button', { name: 'Submit', exact: true })];
    case 57: return [scope.getByRole('textbox')];
    case 75: return ['Overview', 'Code', 'Notes'].map(name => scope.getByRole('tab', { name, exact: true }));
    case 100: return ['Home', 'Patterns', 'About'].map(name => scope.getByRole('tab', { name, exact: true }));
    case 111: return [scope.getByText('Drawer-style navigation sample', { exact: true }), scope.getByText('Settings', { exact: true })];
    case 129: return [scope.getByRole('button', { name: 'Open dialog', exact: true })];
    case 147: return [mergedLeaf(scope, 'AnimatedCrossFade\n#1')];
    case 165: return [scope.getByRole('button', { name: 'Simulate async task', exact: true })];
    case 185: return [scope.getByRole('switch')];
    default: throw Error('Unreviewed template');
  }
}
async function attach(page: Page, info: TestInfo, measurements: unknown) {
  await info.attach('generic-geometry.json', { body: JSON.stringify(measurements, null, 2), contentType: 'application/json' });
  await info.attach('generic-template.png', { body: await page.screenshot(), contentType: 'image/png' });
}
for (const id of layouts) test(`Generic ${id} selected source controls are fully reachable`, async ({ page }, info) => {
  const errors: string[] = [], inputs: unknown[] = [], measurements = [];
  page.on('pageerror', error => errors.push(String(error)));
  try {
  await navigateToScreen(page, id); await expect(template(page)).toHaveCount(1); await delay(page);
  for (const target of targets(page, id)) measurements.push(await reveal(page, target, inputs));
  if (id === 39 || id === 57) {
    const input = template(page).getByRole('textbox'); await focusByTab(page, input);
    await expect(input).toBeFocused(); await page.keyboard.type('reachable'); await expect(input).toHaveValue('reachable');
  } else if (id === 129) {
    await clickMeasured(page, targets(page, id)[0], inputs); await expect(page.getByRole('dialog')).toBeVisible();
    await page.keyboard.press('Escape'); await expect(page.getByRole('dialog')).toHaveCount(0);
  }
  expect(errors).toEqual([]);
  } finally {
    await attach(page, info, { id, scope: 'selected controls only; not all list/grid items', viewport: page.viewportSize(), inputs, measurements, errors });
  }
});

test('Generic form retains live editor through width and minimum-height crossings', async ({ page }, info) => {
  const input = template(page).getByRole('textbox'), inputs: unknown[] = [], frames = [];
  try {
  await navigateToScreen(page, 39); await expect(template(page)).toHaveCount(1); await delay(page);
  await reveal(page, input, inputs); await focusByTab(page, input); await page.keyboard.type('resize-safe');
  await expect(input).toHaveValue('resize-safe'); const original = await input.elementHandle();
  await page.keyboard.press('Home'); await page.keyboard.press('Shift+ArrowRight'); await page.keyboard.press('Shift+ArrowRight');
  const selection = await input.evaluate(el => [(el as HTMLInputElement).selectionStart, (el as HTMLInputElement).selectionEnd]);
  const initial = page.viewportSize()!, initialBody = (await body(page).boundingBox())!;
  const boundary = Math.round(initial.height + 480 - initialBody.height);
  for (const size of [{ width: 390, height: 500 }, { width: 1180, height: 757 },
    ...[-1, 0, 1].map(d => ({ width: initial.width, height: boundary + d })), initial]) {
    await page.setViewportSize(size); await delay(page); await reveal(page, input, inputs);
    expect(await input.evaluate((el, prior) => el === prior, original)).toBe(true); await expect(input).toBeFocused();
    await expect(input).toHaveValue('resize-safe');
    expect(await input.evaluate(el => [(el as HTMLInputElement).selectionStart, (el as HTMLInputElement).selectionEnd])).toEqual(selection);
    frames.push({ size, geometry: await geometry(page, input) });
  }
  // Real input after all crossings proves the retained editor is still live.
  await page.keyboard.press('End'); await page.keyboard.type('x'); await expect(input).toHaveValue('resize-safex');
  await page.keyboard.press('Backspace'); await expect(input).toHaveValue('resize-safe');
  } finally {
    await attach(page, info, { inputs, frames });
  }
});
