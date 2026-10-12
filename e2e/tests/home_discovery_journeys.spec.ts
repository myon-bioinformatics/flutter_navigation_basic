import { test, expect } from '@playwright/test';
import { waitForFlutter } from '../utils/helpers';

test.describe('Home discovery journeys', () => {
  test('visits three distinct Home tools and returns each time @portable', async ({ page }) => {
    // Navigation back to Home is intentionally deterministic; only outbound
    // targets use real, visible user interaction (no coordinate guessing).
    const targets = [
      { label: 'Navigation Hub', route: /#\/hub$/ },
      { label: 'UI Showcase', route: /#\/examples\/ui-showcase$/ },
      { label: 'MCP Integration', route: /#\/examples\/external-integration\/mcp$/ },
    ];
    for (const [index, target] of targets.entries()) {
      await page.goto('/');
      await waitForFlutter(page);
      await expect(page.getByText(target.label, { exact: true }).first()).toBeVisible();
      await page.getByText(target.label, { exact: true }).first().click();
      await waitForFlutter(page);
      await expect(page).toHaveURL(target.route);
      await page.screenshot({ path: `test-results/home-journey-${index + 1}.png` });
      await page.goto('/');
      await waitForFlutter(page);
      await expect(page).toHaveURL(/#\/?$|\/$/);
    }
  });


  test('Door-to-Door dropdown navigates from URL Params to another tool @portable', async ({ page }) => {
    await page.goto('/#/screen5');
    await waitForFlutter(page);
    await expect(page).toHaveURL(/#\\/screen5$/);
    const selector = page.getByText('Door-to-Door tools', { exact: true }).last();
    await expect(selector).toBeVisible();
    // Flutter dropdown is an actual pointer-operated widget, not a native HTML select.
    const selected = page.getByText(/URL Params.*current/).last();
    await selected.click();
    const destination = page.getByText('Photo Studio', { exact: true }).last();
    await expect(destination).toBeVisible();
    await destination.click();
    await waitForFlutter(page);
    await expect(page).toHaveURL(/#\\/examples\\/photo-studio$/);
    await page.screenshot({ path: 'test-results/door-to-door-photo-studio.png' });
  });

  test('random Home discovery card navigates to its numbered screen @portable', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
    const card = page.getByText(/^Screen(?:[6-9]|[1-9][0-9]|1[0-9][0-8]) · /).first();
    await expect(card).toBeVisible();
    const title = (await card.textContent()) ?? '';
    const id = Number(title.match(/^Screen(\d+) · /)?.[1]);
    expect(id).toBeGreaterThanOrEqual(6);
    expect(id).toBeLessThanOrEqual(198);
    await card.click();
    await waitForFlutter(page);
    await expect(page).toHaveURL(new RegExp(`#/screen${id}$`));
    await page.screenshot({ path: 'test-results/home-discovery-destination.png' });
    await page.goto('/');
    await waitForFlutter(page);
  });
});
