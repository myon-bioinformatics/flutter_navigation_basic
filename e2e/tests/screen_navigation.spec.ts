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
    await navigateToScreen(page, 5);
    await expect(page.getByText('Back to Hub', { exact: false })).toBeVisible();
  });

  test('generic screen Back to Hub navigates to hub', async ({ page }) => {
    await navigateToScreen(page, 5);
    await page.getByText('Back to Hub').click();
    await waitForFlutter(page);
    await expect(page.getByText('Navigation Hub', { exact: false })).toBeVisible();
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
      // Screen1 is home, Screen2-4 are legacy, 5+ are generic
      if (screenId >= 5) {
        await expect(page.getByText(`Screen${screenId}`, { exact: false })).toBeVisible();
      } else {
        // Legacy screens still load without errors
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
