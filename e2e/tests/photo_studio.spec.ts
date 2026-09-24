import { test, expect } from '@playwright/test';
import path from 'node:path';
import { waitForFlutter } from '../utils/helpers';

const photoStudioRoute = '/#/tools/media/photo-studio';
// Playwright commands in this repository run with e2e/ as the working directory.
const fixture = path.resolve(
  process.cwd(),
  '../test/fixtures/photo_studio/import_compat/png_opaque_2x2.png',
);

test.describe('Photo Studio representative flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(photoStudioRoute);
    await waitForFlutter(page);
  });

  test('opens the canonical Photo Studio route @portable', async ({ page }) => {
    await expect(page).toHaveURL(/#\/tools\/media\/photo-studio$/);
    await expect(page.getByText('Photo Studio', { exact: true })).toBeVisible();
    await expect(page.getByText('Import image', { exact: true })).toBeVisible();
    await expect(page.getByText('Paste photo', { exact: true })).toBeVisible();
  });

  test('imports a committed PNG through the browser file picker @portable', async ({ page }) => {
    const chooserPromise = page.waitForEvent('filechooser');
    await page.getByText('Import image', { exact: true }).click();
    const chooser = await chooserPromise;
    await chooser.setFiles(fixture);

    await expect(page.getByText('Image loaded', { exact: true })).toBeVisible({
      timeout: 15_000,
    });
    await expect(page.getByText('Replace image', { exact: true })).toBeVisible();
  });
});
