import { test, expect } from '../utils/observed_test';
import { waitForFlutter } from '../utils/helpers';
import { explore } from '../utils/explore';

// Each route has its own page/context and outputPath; no shared mutable state.
test.describe.configure({ mode: 'parallel' });

// The Python CLI derives these from the existing registry + numbered-route TOML.
// No all-page sweep is silently added to the normal per-PR browser matrix.
const catalogue = process.env.FLUTTER_WEB_ROUTES
  ? JSON.parse(process.env.FLUTTER_WEB_ROUTES) : { routes: [] };
for (const route of catalogue.routes as string[]) {
  test(`public page ${route} @portable @page-observation`, async ({ page, baseURL }, info) => {
    info.annotations.push(
      { type: 'exploration_seed', description: process.env.FLUTTER_WEB_EXPLORE_SEED || 'local' },
      { type: 'exploration_steps', description: process.env.FLUTTER_WEB_EXPLORE_STEPS || '0' },
      { type: 'route', description: route },
    );
    const response = await page.goto(new URL(`#${route}`, baseURL!).href);
    expect(response?.ok()).toBeTruthy();
    await waitForFlutter(page, 30_000);
    await expect(page).toHaveURL(url => (url.hash.slice(1) || '/') === route);
    await expect(page.locator('flt-semantics').first()).toBeAttached();
    const steps = Number(process.env.FLUTTER_WEB_EXPLORE_STEPS || '0');
    if (steps > 0) {
      await explore(page, info, route, process.env.FLUTTER_WEB_EXPLORE_SEED || 'local', steps);
      // Avoid another app startup unless a chosen control actually navigated.
      if ((new URL(page.url()).hash.slice(1) || '/') !== route) {
        await page.goto(new URL(`#${route}`, baseURL!).href);
        await waitForFlutter(page, 30_000);
      }
    }
    // Loading a route is smoke evidence, not proof that all controls work.
  });
}
