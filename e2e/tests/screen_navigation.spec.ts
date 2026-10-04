import { test, expect } from '@playwright/test';
import { waitForFlutter, navigateToHub, navigateToScreen } from '../utils/helpers';
import testData from '../fixtures/test_data.json';

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
    await page.getByTitle('List view').click();
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
      await expect(page.getByText('Navigation Hub', { exact: false })).toBeVisible();
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
    // Fill the editable descendant, not the non-editable semantics container.
    const search = searchRegion.getByRole('textbox');
    await expect(search).toHaveCount(1);
    await expect(search).toBeEditable();
    // Keep focus on Flutter's real editable semantics node. Desktop WebKit
    // can expose a changed DOM value without delivering the event sequence
    // Flutter needs to rebuild state, so insert text through the page keyboard.
    await search.click();
    await expect(search).toBeFocused();
    await page.keyboard.insertText('Transformed Result List');
    await expect(search).toHaveValue('Transformed Result List');
    const resultCount = page.locator(
      '[flt-semantics-identifier="screen6-result-count"]',
    );
    await expect(resultCount).toHaveCount(1);
    await expect(resultCount).toContainText('1 / 198');

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
