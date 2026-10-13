import { test, expect, type Locator, type Page } from '@playwright/test';
import { writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { waitForFlutter } from '../utils/helpers';

// Controls are immediately available after Flutter loads; fail with a useful
// locator error instead of spending the full test timeout on a missing action.
test.use({ actionTimeout: 5_000 });
test.setTimeout(60_000);

// Flutter focus semantics may cover a child DOM hit target while forwarding
// native pointer events correctly. Measure the visible control, tap it, and
// verify the resulting production state.
async function press(page: Page, button: Locator, hasTouch: boolean) {
  await expect(button).toBeVisible();
  await expect(button).toBeEnabled();
  const bounds = await button.boundingBox();
  expect(bounds).not.toBeNull();
  const x = bounds!.x + bounds!.width / 2;
  const y = bounds!.y + bounds!.height / 2;
  if (hasTouch) await page.touchscreen.tap(x, y);
  else await page.mouse.click(x, y);
}

const pages: Array<[string, boolean]> = [
  ['/', true], ['/hub', true], ['/core/clipboard-shelf', false],
  ['/tools/time/now-timeline', false], ['/tools/location/coordinates', false],
  ['/tools/media/photo-studio', true], ['/tools/http/request-draft', true],
  ['/examples/ui-showcase', true], ['/examples/composition-generator', false],
  ['/examples/irony-generator', false], ['/examples/external-integration/mcp', false],
  ['/screen6', true], ['/screen8', true], ['/examples/counter-playground', false],
];

for (const [route, requiresSecondary] of pages) {
  test(`shared header ${route} exports measured JSON @portable`, async ({ page }, testInfo) => {
    await page.goto(`/#${route}`);
    await waitForFlutter(page, 30_000);
    const node = (id: string) => page.locator(`[flt-semantics-identifier="${id}"]`);
    const title = node('shared-header-title');
    await expect(title).toBeVisible();
    const ids = ['shared-header-title', 'shared-header-home', 'shared-header-favorite', 'shared-header-menu'];
    if (requiresSecondary) ids.push('shared-header-secondary');
    const boxes: Record<string, unknown> = {};
    for (const id of ids) {
      await expect(node(id)).toHaveCount(1);
      await expect(node(id)).toBeVisible();
      boxes[id] = await node(id).boundingBox();
    }
    const snapshot = { schemaVersion: 1, route, requiresSecondary, title: await title.innerText(), viewport: page.viewportSize(), boxes };
    const output = testInfo.outputPath('header-contract.json');
    writeFileSync(output, JSON.stringify(snapshot, null, 2));
    await testInfo.attach('header-contract', { path: output, contentType: 'application/json' });
    const oracle = spawnSync('python3', ['-S', '../tool/python/header_contracts.py', output], { encoding: 'utf8' });
    expect(oracle.error, String(oracle.error)).toBeUndefined();
    expect(oracle.status, oracle.stdout + oracle.stderr).toBe(0);
    const favorite = node('shared-header-favorite').getByRole('button');
    await expect(favorite).toHaveText('Favorite this page');
    await press(page, favorite, !!testInfo.project.use.hasTouch);
    // A visible Flutter tooltip is aria-owned by its button and can extend the
    // accessible name. Identify the control by its stable region, then inspect
    // the actual updated button text instead of matching the combined name.
    await expect(favorite).toHaveText('Remove favorite');
    await press(page, favorite, !!testInfo.project.use.hasTouch);
    await expect(favorite).toHaveText('Favorite this page');
    await page.mouse.move(0, 200);
    const screenshot = testInfo.outputPath('shared-header.png');
    await page.screenshot({ path: screenshot });
    await testInfo.attach('shared-header', { path: screenshot, contentType: 'image/png' });
    await press(page, node('shared-header-menu').getByRole('button'), !!testInfo.project.use.hasTouch);
    await expect(page.getByRole('button', { name: /^Language / })).toBeVisible();
  });
}


test('shared header Home on Home keeps the page without confirmation @portable', async ({ page }, testInfo) => {
  await page.goto('/#/');
  await waitForFlutter(page, 30_000);
  const title = page.locator('[flt-semantics-identifier="shared-header-title"]');
  const home = page.locator('[flt-semantics-identifier="shared-header-home"]').getByRole('button');
  await expect(title).toContainText('🏠');
  const before = await title.innerText();
  const url = page.url();
  for (let i = 0; i < 3; i++) await press(page, home, !!testInfo.project.use.hasTouch);
  await expect(page.getByText('Return to Home?', { exact: true })).toHaveCount(0);
  await expect(title).toHaveText(before);
  expect(page.url()).toBe(url);
});

test('shared header rapid Home taps allow one confirmation then return from Hub @portable', async ({ page }, testInfo) => {
  await page.goto('/#/hub');
  await waitForFlutter(page, 30_000);
  const title = page.locator('[flt-semantics-identifier="shared-header-title"]');
  await expect(title).toContainText('🗺️');
  const home = page.locator('[flt-semantics-identifier="shared-header-home"]').getByRole('button');
  const bounds = await home.boundingBox();
  expect(bounds).not.toBeNull();
  const x = bounds!.x + bounds!.width / 2;
  const y = bounds!.y + bounds!.height / 2;
  // Confirm the first pointer event opened the modal before testing its barrier.
  await press(page, home, !!testInfo.project.use.hasTouch);
  const dialog = page.getByRole('alertdialog');
  await expect(dialog).toBeVisible();
  // Once the dialog covers Home, two more taps must not silently cancel it.
  for (let i = 0; i < 2; i++) {
    if (testInfo.project.use.hasTouch) await page.touchscreen.tap(x, y);
    else await page.mouse.click(x, y);
  }
  await expect(page.getByText('Return to Home?', { exact: true })).toHaveCount(1);
  await expect(dialog).toHaveCount(1);
  await press(page, dialog.getByRole('button', { name: 'Cancel · Stay here', exact: true }), !!testInfo.project.use.hasTouch);
  await expect(title).toContainText('🗺️');
  await expect(home).toBeEnabled();
  await press(page, home, !!testInfo.project.use.hasTouch);
  await expect(page.getByText('Return to Home?', { exact: true })).toHaveCount(1);
  await press(page, dialog.getByRole('button', { name: 'Home', exact: true }), !!testInfo.project.use.hasTouch);
  await expect(title).toContainText('🏠');
  await expect(title).toHaveCount(1);
  await expect(page.getByText('Return to Home?', { exact: true })).toHaveCount(0);
  const screenshot = testInfo.outputPath('home-navigation.png');
  await page.screenshot({ path: screenshot });
  await testInfo.attach('home-navigation', { path: screenshot, contentType: 'image/png' });
});

// Exercise the production locale picker while the shared menu stays open.
async function selectJapanese(page: Page, touch: boolean) {
  const menu = page.locator('[flt-semantics-identifier="shared-header-menu"]').getByRole('button');
  await press(page, menu, touch);
  await press(page, page.getByRole('button', { name: /^Language / }), touch);
  await press(page, page.getByRole('menuitem', { name: 'JPN', exact: true }), touch);
  // Flutter merges adjacent ListTile text into a single semantics text node.
  await expect(page.getByText('一時クリップボード')).toBeVisible();
  await expect(page.getByText('コピーしたテキストを保存', { exact: true })).toBeVisible();
  await expect(page.getByRole('button', { name: /^言語 / })).toBeVisible();
  // Dismiss the sheet outside its bounds (all viewport sizes).
  if (touch) await page.touchscreen.tap(8, 80);
  else await page.mouse.click(8, 80);
  await expect(page.getByText('一時クリップボード')).toHaveCount(0);
}

test('Japanese shared menu and Home confirmation preserve cancel and navigation @portable', async ({ page }, testInfo) => {
  await page.goto('/#/hub');
  await waitForFlutter(page, 30_000);
  const touch = !!testInfo.project.use.hasTouch;
  await selectJapanese(page, touch);
  const home = page.locator('[flt-semantics-identifier="shared-header-home"]').getByRole('button');
  const favorite = page.locator('[flt-semantics-identifier="shared-header-favorite"]').getByRole('button');
  await expect(home).toHaveText('ホーム');
  await expect(favorite).toHaveText('このページをお気に入りに追加');
  await press(page, favorite, touch);
  await expect(favorite).toHaveText('お気に入りから削除');
  await press(page, home, touch);
  const dialog = page.getByRole('alertdialog');
  await expect(dialog).toContainText('ホームに戻りますか？');
  await expect(dialog).toContainText('未保存の変更');
  const stay = dialog.getByRole('button', { name: 'キャンセル · この画面に留まる', exact: true });
  const go = dialog.getByRole('button', { name: 'ホーム', exact: true });
  expect((await stay.boundingBox())!.width).toBeGreaterThan((await go.boundingBox())!.width);
  await press(page, stay, touch);
  await expect(page.locator('[flt-semantics-identifier="shared-header-title"]')).toContainText('🗺️');
  await press(page, home, touch);
  await press(page, go, touch);
  await expect(page.locator('[flt-semantics-identifier="shared-header-title"]')).toContainText('🏠');
  await expect(dialog).toHaveCount(0);
});

test('Japanese clipboard save and copy use real system clipboard @portable', async ({ page, context }, testInfo) => {
  test.skip(!testInfo.project.name.includes('chromium'), 'Clipboard permissions are supported by Chromium; all outcomes have Widget coverage.');
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  await page.goto('/#/hub');
  await waitForFlutter(page, 30_000);
  const touch = !!testInfo.project.use.hasTouch;
  await selectJapanese(page, touch);
  await page.evaluate(() => navigator.clipboard.writeText('locale clipboard regression'));
  const menu = page.locator('[flt-semantics-identifier="shared-header-menu"]').getByRole('button');
  await press(page, menu, touch);
  await press(page, page.getByRole('button', { name: 'コピーしたテキストを保存', exact: true }), touch);
  await expect(page.getByText('一時クリップボードに保存しました')).toBeVisible();
  await expect(page.getByText('locale clipboard regression')).toBeVisible();
  await page.evaluate(() => navigator.clipboard.writeText('overwritten'));
  await press(page, page.getByRole('button', { name: '保存したテキストをコピー', exact: true }), touch);
  await expect(page.getByText('システムのクリップボードにコピーしました')).toBeVisible();
  expect(await page.evaluate(() => navigator.clipboard.readText())).toBe('locale clipboard regression');
});
