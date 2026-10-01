import { Page } from '@playwright/test';

export async function waitForFlutter(page: Page, timeout = 15000) {
  await page.waitForLoadState('load', { timeout });
  await page.locator('flt-glass-pane').waitFor({ state: 'attached', timeout });

  // Flutter Web keeps its accessibility DOM opt-in. The E2E build usually
  // enables semantics from Dart, while non-E2E callers may still expose the
  // accessibility placeholder. Query/click/recheck in one browser callback so
  // a placeholder removed by Flutter cannot race a second locator operation.
  await page.waitForFunction(
    () => {
      if (document.querySelector('flt-semantics') !== null) {
        return true;
      }

      const placeholder = document.querySelector(
        'flt-semantics-placeholder[aria-label="Enable accessibility"]',
      );
      if (placeholder instanceof HTMLElement) {
        placeholder.click();
      }

      return document.querySelector('flt-semantics') !== null;
    },
    null,
    { timeout },
  );
}

export async function navigateToHub(page: Page) {
  await page.goto('/');
  await waitForFlutter(page);
  // Click the hub button on the home screen
  await page.getByText('Navigation Hub', { exact: false }).click();
  await waitForFlutter(page);
}

export async function navigateToScreen(page: Page, screenId: number) {
  // Open the catalogue route directly; #107's cold probe guards first-load routing.
  await page.goto(`/#/screen${screenId}`);
  await waitForFlutter(page);
}

export async function tapSemantics(
  page: Page,
  label: string,
  { exact = true, timeout = 5_000 }: { exact?: boolean; timeout?: number } = {},
) {
  const element = page.getByRole('button', { name: label, exact }).first();
  try {
    await element.waitFor({ state: 'visible', timeout });
  } catch (error) {
    const detail = String(error).split('\n')[0];
    throw new Error(
      `tapSemantics: "${label}" failed within ${timeout}ms: ${detail}`,
      { cause: error },
    );
  }
  await element.evaluate((node) => (node as HTMLElement).click());
}
