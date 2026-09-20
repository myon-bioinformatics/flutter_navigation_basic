import { expect, test } from '@playwright/test';

test.describe('visual snapshots', () => {
  test('home page', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    await expect(page).toHaveScreenshot('home.png', {
      animations: 'disabled',
      fullPage: true,
    });
  });
});
