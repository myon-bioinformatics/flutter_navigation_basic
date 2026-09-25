import { test, expect, type Page } from '@playwright/test';
import path from 'node:path';
import { waitForFlutter } from '../utils/helpers';

const route = '/#/tools/media/photo-studio';
const fixtureDir = path.resolve(
  process.cwd(),
  '../test/fixtures/photo_studio/import_compat',
);

const portableSupportedCases = [
  ['PNG', 'png_opaque_64x32.png'],
  ['JPEG baseline', 'jpeg_baseline_markers_64x32.jpg'],
  ['JPEG progressive', 'jpeg_progressive_markers_64x32.jpg'],
  ['WebP lossy', 'webp_lossy_64x32.webp'],
  ['WebP lossless', 'webp_lossless_64x32.webp'],
  ['GIF still', 'gif_still_1x1.gif'],
] as const;

async function openPhotoStudio(page: Page) {
  await page.goto(route);
  await waitForFlutter(page);
}

async function pickFixture(page: Page, fileName: string) {
  const chooserPromise = page.waitForEvent('filechooser');
  const importButton = page.getByText('Import image', { exact: true });
  // Flutter may place a sibling semantics node over the labeled button. Target
  // the intended accessibility node directly so that the overlay cannot
  // intercept Playwright's pointer click.
  await importButton.evaluate((element) => (element as HTMLElement).click());
  const chooser = await chooserPromise;
  await chooser.setFiles(path.join(fixtureDir, fileName));
}

test.describe('Photo Studio portable format matrix', () => {
  for (const [label, fileName] of portableSupportedCases) {
    test(`${label} imports successfully through the web picker @portable @format-matrix`, async ({ page }) => {
      await openPhotoStudio(page);
      await pickFixture(page, fileName);

      await expect(page.getByText('Image loaded', { exact: true })).toBeVisible({
        timeout: 15_000,
      });
      await expect(page.getByText('Replace image', { exact: true })).toBeVisible();
    });
  }

  test('truncated PNG is rejected with unsupported-format state @portable @format-matrix', async ({ page }) => {
    await openPhotoStudio(page);
    await pickFixture(page, 'png_truncated.png');

    await expect(
      page.getByText('That image format could not be decoded.', { exact: true }),
    ).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText('Image loaded', { exact: true })).toHaveCount(0);
    await expect(page.getByText('Replace image', { exact: true })).toHaveCount(0);
  });
});
