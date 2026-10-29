import { flutterWorkerBudget } from '../utils/flutter_worker_policy.mjs';
import { test, expect, type Locator } from '@playwright/test';
import { waitForFlutter, navigateToHub, navigateToScreen } from '../utils/helpers';
import testData from '../fixtures/test_data.json';

// Independent page/context fixtures; schedule cases across bounded workers.
test.describe.configure({ mode: 'parallel' });

// Clearing a Flutter TextField can rebuild its suffix semantics and detach the
// WebKit editing strategy. Re-focus before sending the next real key sequence.
async function setCatalogQuery(search: Locator, query: string) {
  await search.click();
  await expect(search).toBeFocused();
  await expect(search).toHaveAttribute('autocorrect', 'on');
  await search.fill('');
  await expect(search).toHaveValue('');
  if (query) {
    await search.click();
    await expect(search).toBeFocused();
    await expect(search).toHaveAttribute('autocorrect', 'on');
    await search.pressSequentially(query, { delay: 50 });
  }
  await expect(search).toHaveValue(query);
}


test.describe('Screen Navigation', () => {
  test('navigates to Screen1 from hub', async ({ page }) => {
    await navigateToHub(page);
    await page.locator('[key="screen-grid-1"]').click();
    await waitForFlutter(page);
    await expect(page.getByText('Screen1', { exact: false })).toBeVisible();
  });

  test('navigates to Screen5 from hub', async ({ page }) => {
    await navigateToHub(page);
    // Use list mode to find screen 5
    const listMode = page.locator('[flt-semantics-identifier="hub-list-view"]');
    await expect(listMode).toBeVisible();
    await listMode.click();
    await waitForFlutter(page);
    await page.locator('[key="screen-item-5"]').click();
    await waitForFlutter(page);
    await expect(page.getByText('Screen5', { exact: false })).toBeVisible();
  });

  test('generic screen shows Back to Hub button', async ({ page }) => {
    // /screen5 is Screen5Page (URL Params), not GenericScreen — use a catalogue id.
    await navigateToScreen(page, 6);
    await expect(page.locator('[flt-semantics-identifier="back-to-hub"]')).toHaveCount(1);
  });

  test('generic screen Back to Hub navigates via semantics action @portable', async ({ page }) => {
    await navigateToScreen(page, 6);
    const button = page.locator('[flt-semantics-identifier="back-to-hub"]');
    let stage = 'attached';
    const beforeHash = await page.evaluate(() => window.location.hash);
    const semanticsEnabled = (await page.locator('flt-semantics').count()) > 0;
    let count = 0;
    try {
      await expect(button).toHaveCount(1, { timeout: 5_000 });
      count = await button.count();
      console.log('[back-to-hub probe] pre-action', {
        stage,
        semanticsEnabled,
        count,
        beforeHash,
      });
      stage = 'tappable';
      const probe = await button.evaluate((element) => ({
        role: element.getAttribute('role'),
        tappable: element.hasAttribute('flt-tappable'),
        childTappable: !!element.querySelector('[flt-tappable]'),
      }));
      console.log('[back-to-hub probe] target', { stage, ...probe });
      expect(probe.tappable).toBe(true);
      stage = 'action';
      await button.evaluate((element) => (element as HTMLElement).click());
      await waitForFlutter(page);
      await expect(page).toHaveURL(/#\/hub$/, { timeout: 5_000 });
      const afterHash = await page.evaluate(() => window.location.hash);
      console.log('[back-to-hub probe] post-action', { stage, beforeHash, afterHash });
      const title = page.locator('[flt-semantics-identifier="shared-header-title"]');
      await expect(title).toBeVisible();
      await expect(title).toContainText('Navigation Hub');
      await expect(page.locator('[flt-semantics-identifier="shared-header-title"]')).toBeVisible();
    } catch (error) {
      count = await button.count().catch(() => -1);
      const identifiers = await page.locator('[flt-semantics-identifier]').evaluateAll(
        (nodes) => nodes.map((node) => node.getAttribute('flt-semantics-identifier')),
      );
      console.log('[back-to-hub probe] failure', {
        stage,
        semanticsEnabled,
        count,
        beforeHash,
        identifiers,
      });
      throw error;
    }
  });

  test('direct cold deep link to Screen6 renders without Home warm-up @portable', async ({ page }) => {
    // Regression probe for #107: keep the first navigation explicit so this
    // still proves a cold deep link if shared helpers change in the future.
    await page.goto('/#/screen6');
    await waitForFlutter(page);
    await expect(page).toHaveURL(/#\/screen6$/);
    // Flutter hint text is localized and is not a DOM placeholder contract.
    const searchRegion = page.locator('[flt-semantics-identifier="screen6-search"]');
    await expect(searchRegion).toHaveCount(1);
    await expect(searchRegion).toBeVisible();
    await expect(searchRegion.getByRole('textbox')).toHaveCount(1);
    await expect(page.locator('[flt-semantics-identifier="back-to-hub"]')).toHaveCount(1);
  });

  test('Screen6 searches the catalogue and opens Screen5 @portable', async ({ page }) => {
    await navigateToScreen(page, 6);
    const searchRegion = page.locator('[flt-semantics-identifier="screen6-search"]');
    await expect(searchRegion).toHaveCount(1);
    await expect(searchRegion).toBeVisible();
    // Type into the editable descendant, not the semantics container.
    const search = searchRegion.getByRole('textbox');
    await expect(search).toHaveCount(1);
    await expect(search).toBeEditable();
    // DOM focus precedes Flutter's editing-strategy activation on WebKit.
    // The engine creates this input with autocorrect=off, then applies the
    // TextField's default autocorrect=on when it attaches input listeners.
    await search.click();
    await expect(search).toBeFocused();
    await expect(search).toHaveAttribute('autocorrect', 'on');
    // Give each real key event a frame to propagate before the next key.
    await search.pressSequentially('Transformed Result List', { delay: 50 });
    await expect(search).toHaveValue('Transformed Result List');
    const resultCount = page.locator(
      '[flt-semantics-identifier="screen6-result-count"]',
    );
    await expect(resultCount).toHaveCount(1);
    await expect(resultCount).toHaveText('1 / 198');

    const result = page.locator(
      '[flt-semantics-identifier="screen6-result-5"]',
    );
    await expect(result).toHaveCount(1);
    await expect(result).toBeVisible();
    // Keep navigation tied to the row's real Flutter semantics tap action.
    const tapTarget = result.locator('[flt-tappable]');
    await expect(tapTarget).toHaveCount(1);
    await tapTarget.evaluate((element) => {
      if (!(element instanceof HTMLElement)) {
        throw new Error('Screen5 catalogue result tap target is not an HTMLElement');
      }
      element.click();
    });
    await waitForFlutter(page);
    await expect(page).toHaveURL(/#\/screen5$/);
  });


  test('Hub use-case filtering, zero results, clear and Screen5 route @portable', async ({ page }) => {
    await navigateToHub(page);
    const listMode = page.locator('[flt-semantics-identifier="hub-list-view"]');
    await expect(listMode).toBeVisible();
    await listMode.click();
    const search = page.locator('[flt-semantics-identifier="hub-search"]').getByRole('textbox');
    const rows = page.locator('[flt-semantics-identifier^="hub-result-"]');
    const result5 = page.locator('[flt-semantics-identifier="hub-result-5"]');
    const result6 = page.locator('[flt-semantics-identifier="hub-result-6"]');
    await setCatalogQuery(search, 'Transformed Result List');
    await expect(rows).toHaveCount(1);
    await expect(result5).toBeVisible();
    await expect(result6).toHaveCount(0);
    await setCatalogQuery(search, 'no_such_use_case_144');
    await expect(rows).toHaveCount(0);
    await setCatalogQuery(search, '');
    // Check restored ordering among rendered rows; the full list is lazy.
    await expect(rows.nth(0)).toHaveAttribute('flt-semantics-identifier', 'hub-result-1');
    await expect(rows.nth(1)).toHaveAttribute('flt-semantics-identifier', 'hub-result-2');
    await setCatalogQuery(search, 'screen6');
    await expect(rows.first()).toHaveAttribute('flt-semantics-identifier', 'hub-result-6');
    await expect(result6).toBeVisible();
    await setCatalogQuery(search, 'Transformed Result List');
    await expect(rows).toHaveCount(1);
    const tapTarget = result5.locator('[flt-tappable]');
    await expect(tapTarget).toHaveCount(1);
    await tapTarget.evaluate((element) => (element as HTMLElement).click());
    await waitForFlutter(page);
    await expect(page).toHaveURL(/#\/screen5$/);
  });

  test('Screen6 excludes unrelated results, handles zero matches and clear @portable', async ({ page }) => {
    await navigateToScreen(page, 6);
    const search = page.locator('[flt-semantics-identifier="screen6-search"]').getByRole('textbox');
    const resultCount = page.locator('[flt-semantics-identifier="screen6-result-count"]');
    const result5 = page.locator('[flt-semantics-identifier="screen6-result-5"]');
    const result6 = page.locator('[flt-semantics-identifier="screen6-result-6"]');
    await setCatalogQuery(search, 'Transformed Result List');
    await expect(resultCount).toHaveText('1 / 198');
    await expect(result5).toBeVisible();
    await expect(result6).toHaveCount(0);
    await setCatalogQuery(search, 'no_such_use_case_144');
    await expect(resultCount).toHaveText('0 / 198');
    await expect(result5).toHaveCount(0);
    const clear = page.locator('[flt-semantics-identifier="screen6-clear"]').getByRole('button');
    await expect(clear).toBeVisible();
    await clear.click();
    await expect(search).toHaveValue('');
    await expect(resultCount).toHaveText('198 / 198');
    await expect(page.locator('[flt-semantics-identifier="screen6-result-1"]')).toBeVisible();
    // Re-enter through the live editing strategy after clicking Clear. The
    // count confirms filtering happened before inspecting a virtualized row.
    await setCatalogQuery(search, 'screen6');
    await expect(search).toHaveValue('screen6');
    await expect(resultCount).toHaveText('11 / 198');
    await expect(result6).toBeVisible();
    await clear.click();
    await expect(search).toHaveValue('');
    await expect(resultCount).toHaveText('198 / 198');
    await expect(page.locator('[flt-semantics-identifier="screen6-result-1"]')).toBeVisible();
  });

  for (const screenId of testData.sampleScreenIds) {
    test(`navigates to Screen${screenId} via direct URL`, async ({ page }) => {
      await navigateToScreen(page, screenId);
      // Screen2/3/4 are legacy screens with their own navigation
      if (screenId === 1 || screenId >= 5) {
        await expect(page.getByText(`Screen${screenId}`, { exact: false })).toBeVisible();
      } else {
        // Legacy screens (2-4) still load without errors
        await expect(page).toHaveURL(new RegExp(`screen${screenId}`));
      }
    });
  }

  test('Screen198 loads correctly', async ({ page }) => {
    await navigateToScreen(page, 198);
    await expect(page.getByText('Screen198', { exact: false })).toBeVisible();
    await expect(page.getByText('Back to Hub', { exact: false })).toBeVisible();
  });
});


test('Flutter worker policy preserves light capacity and explicit overrides @portable', () => {
  const previousOverride = process.env.FLUTTER_WEB_WORKERS;
  delete process.env.FLUTTER_WEB_WORKERS;
  try {
    const resources = { cpus: 8, memory: 16 * 1024 ** 3 };
    expect(flutterWorkerBudget({ ...resources, light: false, override: undefined })).toBe(2);
    expect(flutterWorkerBudget({ ...resources, light: true, override: undefined })).toBe(4);
    expect(flutterWorkerBudget({ cpus: 1, memory: 1024 ** 3, light: false, override: undefined })).toBe(1);
    for (const light of [false, true]) {
      expect(flutterWorkerBudget({ ...resources, light, override: '1' })).toBe(1);
      expect(flutterWorkerBudget({ ...resources, light, override: '3' })).toBe(3);
      expect(() => flutterWorkerBudget({ ...resources, light, override: '0' })).toThrow();
    }
  } finally {
    if (previousOverride === undefined) delete process.env.FLUTTER_WEB_WORKERS;
    else process.env.FLUTTER_WEB_WORKERS = previousOverride;
  }
});

// #223's published audit remains the failing baseline. These cases exercise
// the independently built application, never the audit's pinned deployment.
for (const viewport of [{ width: 390, height: 500 }, { width: 1180, height: 757 }]) {
  for (const input of ['mouse', 'keyboard'] as const) {
    test(`Screen6 search stays inside body ${viewport.width}x${viewport.height} ${input} @portable`, async ({ page }, testInfo) => {
      test.skip(input === 'mouse' && !!testInfo.project.use.isMobile,
        'Mouse/wheel contract uses desktop pointer projects; mobile touch is separate.');
      await page.setViewportSize(viewport);
      await navigateToScreen(page, 6);
      const body = page.locator('[flt-semantics-identifier="screen6-body"]');
      const region = page.locator('[flt-semantics-identifier="screen6-search"]');
      const count = page.locator('[flt-semantics-identifier="screen6-result-count"]');
      const search = region.getByRole('textbox');
      await expect(body).toHaveCount(1);
      const initialBody = await body.boundingBox();
      expect(initialBody).not.toBeNull();
      expect(initialBody!.height).toBeGreaterThan(100);

      if (input === 'mouse') {
        // Real wheel input over the body, not DOM scrollIntoView or forced tap.
        await page.mouse.move(initialBody!.x + 20, initialBody!.y + initialBody!.height / 2);
        if (viewport.width === 390) await page.mouse.wheel(0, 350);
      } else {
        // Start cold and reach the editable via real tab traversal. Do not
        // focus it with evaluate(), locator.focus(), or a preceding mouse click.
        for (let attempt = 0; attempt < 40; attempt++) {
          if (await search.evaluate(el => el.matches(':focus'))) break;
          await page.keyboard.press('Tab');
          // Flutter exports logical focus to the semantics DOM during a frame.
          // A timer can expire before that frame on a cold WebKit page, so the
          // next Tab skips the editable before its DOM focus is observable.
          // Cross two frame boundaries to cover callback ordering, not a fixed
          // delay; keep the real keyboard traversal and focus assertions.
          await page.evaluate(() => new Promise<void>(resolve => {
            requestAnimationFrame(() => requestAnimationFrame(() => resolve()));
          }));
        }
        await expect(search).toBeFocused();
      }

      const measure = async () => ({
        body: await body.boundingBox(),
        search: await region.boundingBox(),
        count: await count.boundingBox(),
      });
      // Fully contained controls, not just Playwright's nonzero DOM visibility.
      await expect.poll(async () => {
        const boxes = await measure();
        if (!boxes.body || !boxes.search || !boxes.count) return false;
        return [boxes.search, boxes.count].every(box =>
          box.y >= boxes.body!.y - 1 &&
          box.y + box.height <= boxes.body!.y + boxes.body!.height + 1 &&
          box.height > 0);
      }).toBe(true);
      if (input === 'mouse') await search.click();
      await expect(search).toBeFocused();
      await expect(search).toHaveAttribute('autocorrect', 'on');
      await search.pressSequentially('Transformed Result List', { delay: 50 });
      await expect(search).toHaveValue('Transformed Result List');
      await expect(count).toHaveText('1 / 198');
      await testInfo.attach('screen6-body-geometry.json', {
        body: JSON.stringify({ viewport, input, initialBody, final: await measure() }, null, 2),
        contentType: 'application/json',
      });
      await testInfo.attach('screen6-search.png', {
        body: await page.screenshot(), contentType: 'image/png',
      });
    });
  }
}
