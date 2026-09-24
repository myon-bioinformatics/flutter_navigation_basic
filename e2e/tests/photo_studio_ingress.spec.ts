import { test, expect, type Page } from '@playwright/test';
import path from 'node:path';
import fs from 'node:fs';
import { waitForFlutter } from '../utils/helpers';

const route = '/#/tools/media/photo-studio';
const fixtureDir = path.resolve(process.cwd(), '../test/fixtures/photo_studio/import_compat');
const pngFixture = path.join(fixtureDir, 'png_opaque_2x2.png');

async function openPhotoStudio(page: Page) {
  await page.goto(route);
  await waitForFlutter(page);
}

test.describe('Photo Studio ingress audit', () => {
  test('picker accepts the committed PNG through the shared import pipeline @portable', async ({ page }) => {
    await openPhotoStudio(page);
    const chooserPromise = page.waitForEvent('filechooser');
    await page.getByText('Import image', { exact: true }).click();
    const chooser = await chooserPromise;
    await chooser.setFiles(pngFixture);
    await expect(page.getByText('Image loaded', { exact: true })).toBeVisible({ timeout: 15_000 });
  });

  test('paste text data URL reaches the same success state @portable', async ({ page, context }) => {
    await context.grantPermissions(['clipboard-read', 'clipboard-write']);
    await openPhotoStudio(page);
    const base64 = fs.readFileSync(pngFixture).toString('base64');
    await page.evaluate(async (value) => {
      await navigator.clipboard.writeText(value);
    }, `data:image/png;base64,${base64}`);
    await page.getByText('Paste photo', { exact: true }).click();
    await expect(page.getByText('Image loaded', { exact: true })).toBeVisible({ timeout: 15_000 });
  });

  test('picker rejects a declared non-image payload before decode @portable', async ({ page }) => {
    await openPhotoStudio(page);
    const chooserPromise = page.waitForEvent('filechooser');
    await page.getByText('Import image', { exact: true }).click();
    const chooser = await chooserPromise;
    await chooser.setFiles({
      name: 'not-an-image.txt',
      mimeType: 'text/plain',
      buffer: Buffer.from('not an image'),
    });
    await expect(page.getByText('Image loaded', { exact: true })).toHaveCount(0);
    await expect(page.getByText('Replace image', { exact: true })).toHaveCount(0);
  });
});
