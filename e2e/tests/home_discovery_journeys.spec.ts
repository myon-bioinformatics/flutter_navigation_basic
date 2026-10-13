import { test, expect } from '@playwright/test';
import { createHash } from 'node:crypto';
import { writeFileSync } from 'node:fs';
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
    await expect(page).toHaveURL(/#\/screen5$/);
    const selector = page.getByText('Door-to-Door tools', { exact: true }).last();
    await expect(selector).toBeVisible();
    // Flutter dropdown is an actual pointer-operated widget, not a native HTML select.
    const selected = page.getByText(/URL Params.*current/).last();
    await selected.click();
    const destination = page.getByText('Photo Studio', { exact: true }).last();
    await expect(destination).toBeVisible();
    await destination.click();
    await waitForFlutter(page);
    await expect(page).toHaveURL(/#\/tools\/media\/photo-studio$/);
    await page.screenshot({ path: 'test-results/door-to-door-photo-studio.png' });
  });

  test('Home draw → Door → second drawn screen with screenshot evidence @portable', async ({ page }, testInfo) => {
    const cardPattern = /^Screen(?:[6-9]|[1-9][0-9]|1[0-9][0-8]) · /;
    const captures: Array<{
      stage: string; route: string; header: string;
      file: string; bytes: number; sha256: string;
    }> = [];

    async function capture(stage: string, file: string) {
      const path = testInfo.outputPath(file);
      const png = await page.screenshot({ path, animations: 'disabled' });
      expect(png.subarray(0, 8).toString('hex')).toBe('89504e470d0a1a0a');
      expect(png.length).toBeGreaterThan(1000);
      const header = await page.locator('[flt-semantics-identifier="shared-header-title"]').innerText();
      captures.push({
        stage, route: new URL(page.url()).hash,
        header, file, bytes: png.length,
        sha256: createHash('sha256').update(png).digest('hex'),
      });
      await testInfo.attach(file, { path, contentType: 'image/png' });
    }

    await page.goto('/');
    await waitForFlutter(page);
    const cards = page.getByText(cardPattern);
    const labels = await cards.allTextContents();
    expect(labels).toHaveLength(3);
    const ids = labels.map((label) => Number(label.match(/^Screen(\d+) · /)?.[1]));
    expect(ids.every((id) => Number.isInteger(id) && id >= 6 && id <= 198)).toBeTruthy();
    expect(new Set(ids).size).toBe(3);

    await cards.first().scrollIntoViewIfNeeded();
    await expect(cards.first()).toBeInViewport();
    await capture('home-draw', 'home-draw.png');
    await cards.first().click();
    await waitForFlutter(page);
    await expect(page).toHaveURL(new RegExp(`#/screen${ids[0]}$`));
    await capture('first-screen', 'first-screen.png');

    // The destination exists because Home published the *same* chosen triple,
    // not because Door independently shuffled the precomputed draw fixture.
    const footer = page.getByText('Door-to-Door tools', { exact: true }).last();
    await footer.scrollIntoViewIfNeeded();
    await expect(footer).toBeInViewport();
    await capture('door', 'door.png');
    await page.getByText(new RegExp(`Screen${ids[0]}.*current`)).last().click();
    const second = page.getByText(labels[1], { exact: true }).last();
    await second.scrollIntoViewIfNeeded();
    await expect(second).toBeVisible();
    await second.click();
    await waitForFlutter(page);
    await expect(page).toHaveURL(new RegExp(`#/screen${ids[1]}$`));
    await capture('second-screen', 'second-screen.png');

    const manifest = testInfo.outputPath('route-audit.json');
    writeFileSync(manifest, JSON.stringify({
      schema: 'flutter-door-route-audit/1',
      stage: 'complete',
      project: testInfo.project.name,
      source: 'Home discovery → rendered Door-to-Door',
      ids,
      labels,
      viewport: page.viewportSize(),
      expected_sha: process.env.EXPECTED_SHA ?? null,
      ci_sha: process.env.GITHUB_SHA ?? null,
      captures,
    }, null, 2));
    await testInfo.attach('route-audit.json', { path: manifest, contentType: 'application/json' });

    await page.goto('/');
    await waitForFlutter(page);
    await expect(page).toHaveURL(/#\/?$|\/$/);
  });
});
