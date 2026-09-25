import { test, expect } from '@playwright/test';
import { waitForFlutter, navigateToHub, navigateToScreen } from '../utils/helpers';
import testData from '../fixtures/test_data.json';

test.describe('Screen Navigation', () => {
  test.beforeEach(({}, testInfo) => {
    test.fixme(
      testInfo.project.name === 'mobile-chromium',
      'semantics bootstrap: tracked in #96',
    );
  });
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
    await navigateToScreen(page, 5);
    await expect(page.getByText('Back to Hub', { exact: false })).toBeVisible();
  });

  test('generic screen Back to Hub navigates via semantics action @portable', async ({ page }) => {
    await navigateToScreen(page, 5);
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
      await expect(page).toHaveURL(/#\/hub/, { timeout: 5_000 });
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

  test('generic screen shows pattern info', async ({ page }) => {
    await navigateToScreen(page, 5);
    // Should show pattern cards
    await expect(page.getByText('Navigation', { exact: false })).toBeVisible();
    await expect(page.getByText('API', { exact: false })).toBeVisible();
    await expect(page.getByText('Theme', { exact: false })).toBeVisible();
    await expect(page.getByText('Data', { exact: false })).toBeVisible();
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
