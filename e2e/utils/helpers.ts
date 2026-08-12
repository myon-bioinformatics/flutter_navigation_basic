import { Page, expect } from '@playwright/test';

export async function waitForFlutter(page: Page, timeout = 15000) {
  await page.waitForFunction(
    () => document.readyState === 'complete',
    { timeout }
  );
  // Wait for Flutter to initialize
  await page.waitForTimeout(2000);
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
