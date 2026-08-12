import { Page, expect } from '@playwright/test';

export async function waitForFlutter(page: Page, timeout = 15000) {
  await page.waitForLoadState('load', { timeout });
  // Wait for Flutter canvas or a rendered element to be visible
  try {
    await page.waitForSelector('flt-glass-pane, canvas, [flt-renderer]', { timeout: 8000 });
  } catch {
    // Fallback: wait a short time if Flutter element selectors are not available
    await page.waitForTimeout(1000);
  }
}

export async function navigateToHub(page: Page) {
  await page.goto('/');
  await waitForFlutter(page);
  // Click the hub button on the home screen
  await page.getByText('Navigation Hub', { exact: false }).click();
  await waitForFlutter(page);
}

export async function navigateToScreen(page: Page, screenId: number) {
  await page.goto(`/#/screen${screenId}`);
  await waitForFlutter(page);
}
