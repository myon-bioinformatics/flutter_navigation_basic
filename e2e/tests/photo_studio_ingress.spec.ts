import { test, expect } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import {
  openPhotoStudio,
  clickPhotoStudioAction,
  pickPhotoFixture,
  waitPhotoImportOutcome,
} from '../utils/photo_studio';

const pngFixtureName = 'png_opaque_64x32.png';
const pngFixture = path.resolve(
  process.cwd(),
  '../test/fixtures/photo_studio/import_compat',
  pngFixtureName,
);

test.describe('Photo Studio ingress audit', () => {
  // Picker/MIME checks are portable. Clipboard write permission is exercised only
  // by Chromium projects; Firefox/WebKit skip before grantPermissions().
  test('picker accepts the committed PNG through the shared import pipeline @portable', async ({ page }) => {
    await openPhotoStudio(page);
    await pickPhotoFixture(page, pngFixtureName);
    expect(await waitPhotoImportOutcome(page)).toBe('rendered');
  });

  test('paste text data URL reaches the same success state @portable @chromium-clipboard', async ({ page, context, browserName }) => {
    test.skip(browserName !== 'chromium', 'Playwright clipboard permissions are Chromium-only in this lane');
    await context.grantPermissions(['clipboard-read', 'clipboard-write']);
    await openPhotoStudio(page);
    const base64 = fs.readFileSync(pngFixture).toString('base64');
    await page.evaluate(async (value) => {
      await navigator.clipboard.writeText(value);
    }, `data:image/png;base64,${base64}`);
    await clickPhotoStudioAction(page, 'Paste photo');
    expect(await waitPhotoImportOutcome(page)).toBe('rendered');
  });

  test('picker rejects a declared non-image payload with unsupported-format state @portable', async ({ page }) => {
    await openPhotoStudio(page);
    const chooserPromise = page.waitForEvent('filechooser');
    await clickPhotoStudioAction(page, 'Import image');
    const chooser = await chooserPromise;
    await chooser.setFiles({ name: 'not-an-image.txt', mimeType: 'text/plain', buffer: Buffer.from('not an image') });
    await expect(
      page.getByText('That image format could not be decoded.', { exact: true }),
    ).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText('Replace image', { exact: true })).toHaveCount(0);
  });
});
