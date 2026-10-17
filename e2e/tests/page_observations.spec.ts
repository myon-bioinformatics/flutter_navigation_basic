import { test, expect } from '../utils/observed_test';
import { waitForFlutter } from '../utils/helpers';

// The Python CLI derives these from the existing registry + numbered-route TOML.
// No all-page sweep is silently added to the normal per-PR browser matrix.
const catalogue = process.env.FLUTTER_WEB_ROUTES
  ? JSON.parse(process.env.FLUTTER_WEB_ROUTES) : { routes: [] };
for (const route of catalogue.routes as string[]) {
  test(`public page ${route} @portable @page-observation`, async ({ page, baseURL }) => {
    const response = await page.goto(new URL(`#${route}`, baseURL!).href);
    expect(response?.ok()).toBeTruthy();
    await waitForFlutter(page, 30_000);
    await expect(page).toHaveURL(url => (url.hash.slice(1) || '/') === route);
    await expect(page.locator('flt-semantics').first()).toBeAttached();
    // Loading a route is smoke evidence, not proof that all controls work.
  });
}
