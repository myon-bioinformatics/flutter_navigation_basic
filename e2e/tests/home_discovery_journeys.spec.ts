import { test, expect, type Locator, type Page, type TestInfo } from '@playwright/test';
import { createHash } from 'node:crypto';
import { writeFileSync } from 'node:fs';
import { waitForFlutter } from '../utils/helpers';

// Flutter paints the controls; semantics may be covered by a focus node.
// Use measured, in-viewport pointer/touch input, not a synthetic DOM click.
async function press(page: Page, target: Locator, testInfo: TestInfo) {
  await target.scrollIntoViewIfNeeded();
  await expect(target).toBeInViewport({ ratio: 0.9 });
  const box = await target.boundingBox();
  expect(box).not.toBeNull();
  const x = box!.x + box!.width / 2;
  const y = box!.y + box!.height / 2;
  if (testInfo.project.use.hasTouch) await page.touchscreen.tap(x, y);
  else await page.mouse.click(x, y);
}

test.describe('Home discovery journeys', () => {
  test.setTimeout(90_000);
  test.use({ actionTimeout: 10_000 });

  test('visits three distinct Home tools and returns each time @portable', async ({ page }, testInfo) => {
    const targets = [
      { label: 'Navigation Hub', route: /#\/hub$/ },
      { label: 'UI Showcase', route: /#\/examples\/ui-showcase$/ },
      { label: 'MCP Integration', route: /#\/examples\/external-integration\/mcp$/ },
    ];
    for (const [index, target] of targets.entries()) {
      await page.goto('/');
      await waitForFlutter(page);
      await press(page, page.getByText(target.label, { exact: true }).first(), testInfo);
      await waitForFlutter(page);
      await expect(page).toHaveURL(target.route);
      const path = testInfo.outputPath(`home-journey-${index + 1}.png`);
      await page.screenshot({ path });
      await testInfo.attach(`home-journey-${index + 1}`, { path, contentType: 'image/png' });
      await page.goto('/');
      await waitForFlutter(page);
      await expect(page).toHaveURL(/#\/?$|\/$/);
    }
  });

  test('Door-to-Door dropdown navigates from URL Params to another tool @portable', async ({ page }, testInfo) => {
    await page.goto('/#/screen5');
    await waitForFlutter(page);
    await expect(page).toHaveURL(/#\/screen5$/);
    await press(page, page.getByText(/URL Params.*current/).last(), testInfo);
    await press(page, page.getByText('Photo Studio', { exact: true }).last(), testInfo);
    await waitForFlutter(page);
    await expect(page).toHaveURL(/#\/tools\/media\/photo-studio$/);
    const path = testInfo.outputPath('door-to-door-photo-studio.png');
    await page.screenshot({ path });
    await testInfo.attach('door-to-door-photo-studio', { path, contentType: 'image/png' });
  });

  test('Home draw → stable tool Door → drawn screen with screenshot evidence @portable', async ({ page }, testInfo) => {
    // Match every numbered card, including 109/119/.../189, then validate IDs.
    const cardPattern = /^Screen\d+ · /;
    const captures: Array<{
      stage: string; route: string; header: string; header_source: string;
      file: string; bytes: number; sha256: string;
    }> = [];
    const title = page.locator('[flt-semantics-identifier="shared-header-title"]');

    async function capture(stage: string, file: string, sourceHeader?: string) {
      // An open Flutter dropdown may hide the underlying page's semantics.
      // For that one capture, retain the title measured before opening it.
      const header = sourceHeader ?? await title.innerText();
      const path = testInfo.outputPath(file);
      const png = await page.screenshot({ path, animations: 'disabled' });
      expect(png.subarray(0, 8).toString('hex')).toBe('89504e470d0a1a0a');
      expect(png.length).toBeGreaterThan(1000);
      captures.push({
        stage, route: new URL(page.url()).hash,
        header, header_source: sourceHeader === undefined ? 'current-page' : 'source-tool-before-menu',
        file, bytes: png.length,
        sha256: createHash('sha256').update(png).digest('hex'),
      });
      await testInfo.attach(file, { path, contentType: 'image/png' });
    }

    await page.goto('/');
    await waitForFlutter(page);
    const cards = page.getByText(cardPattern);
    await expect(cards).toHaveCount(3);
    const labels = await cards.allTextContents();
    const ids = labels.map((label) => Number(label.match(/^Screen(\d+) · /)?.[1]));
    expect(ids.every((id) => Number.isInteger(id) && id >= 6 && id <= 198)).toBeTruthy();
    expect(new Set(ids).size).toBe(3);

    await cards.first().scrollIntoViewIfNeeded();
    await expect(cards.first()).toBeInViewport();
    await capture('home-draw', 'home-draw.png');
    await press(page, page.getByText('Photo Studio', { exact: true }).first(), testInfo);
    await waitForFlutter(page);
    await expect(page).toHaveURL(/#\/tools\/media\/photo-studio$/);
    await capture('source-tool', 'source-tool.png');
    const sourceHeader = await title.innerText();

    await press(page, page.getByText(/Photo Studio.*current/).last(), testInfo);
    const destination = page.getByText(labels[0], { exact: true }).last();
    await destination.scrollIntoViewIfNeeded();
    await expect(destination).toBeInViewport();
    await capture('door-menu', 'door-menu.png', sourceHeader);
    await press(page, destination, testInfo);
    await waitForFlutter(page);
    await expect(page).toHaveURL((url) => url.hash === `#/screen${ids[0]}`);
    await capture('discovered-screen', 'discovered-screen.png');

    await page.goto('/');
    await waitForFlutter(page);
    await expect(page).toHaveURL(/#\/?$|\/$/);
    // A complete receipt is only written after the return leg also succeeds.
    const manifest = testInfo.outputPath('route-audit.json');
    writeFileSync(manifest, JSON.stringify({
      schema: 'flutter-door-route-audit/1',
      stage: 'complete',
      project: testInfo.project.name,
      source: 'Home discovery → rendered Door-to-Door',
      ids, labels,
      viewport: page.viewportSize(),
      expected_sha: process.env.EXPECTED_SHA ?? null,
      ci_sha: process.env.GITHUB_SHA ?? null,
      run_id: process.env.GITHUB_RUN_ID ?? null,
      run_attempt: process.env.GITHUB_RUN_ATTEMPT ?? null,
      captures,
    }, null, 2));
    await testInfo.attach('route-audit.json', { path: manifest, contentType: 'application/json' });
  });
});
