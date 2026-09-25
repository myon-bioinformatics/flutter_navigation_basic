import { Page } from '@playwright/test';

export async function waitForFlutter(page: Page, timeout = 15000) {
  await page.waitForLoadState('load', { timeout });
  await page.locator('flt-glass-pane').waitFor({ state: 'attached', timeout });

  // Flutter Web keeps its accessibility DOM opt-in. Playwright text locators
  // cannot see the app's labels until this placeholder is activated.
  await page.waitForFunction(
    () =>
      document.querySelector('flt-semantics-placeholder[aria-label="Enable accessibility"]') !== null ||
      document.querySelector('flt-semantics') !== null,
    null,
    { timeout },
  );

  const accessibilityButton = page.locator(
    'flt-semantics-placeholder[aria-label="Enable accessibility"]',
  );
  if (await accessibilityButton.isVisible()) {
    // Flutter positions this 1x1px placeholder at (-1px, -1px), outside the
    // viewport; use its DOM click handler instead of a pointer-based click.
    await accessibilityButton.evaluate((element: HTMLElement) => element.click());
  }

  await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout });
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

export async function tapSemantics(
  page: Page,
  label: string,
  { exact = true, timeout = 5_000 }: { exact?: boolean; timeout?: number } = {},
) {
  const element = page.getByText(label, { exact });
  try {
    await element.waitFor({ state: 'visible', timeout });
  } catch (error) {
    throw new Error(`tapSemantics: "${label}" not found within ${timeout}ms`, {
      cause: error,
    });
  }
  await element.evaluate((node) => (node as HTMLElement).click());
}
