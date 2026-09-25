import { test, expect } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import {
  openPhotoStudio,
  pickPhotoFixture,
  waitPhotoImportOutcome,
} from '../utils/photo_studio';
import { tapSemantics } from '../utils/helpers';

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
    expect((await waitPhotoImportOutcome(page)).kind).toBe('rendered');
  });

  test('paste text data URL reaches the same success state @portable @chromium-clipboard', async ({ page, context, browserName }) => {
    test.skip(browserName !== 'chromium', 'Playwright clipboard permissions are Chromium-only in this lane');
    await context.grantPermissions(['clipboard-read', 'clipboard-write']);
    await openPhotoStudio(page);
    const base64 = fs.readFileSync(pngFixture).toString('base64');
    await page.evaluate(async (value) => {
      await navigator.clipboard.writeText(value);
    }, `data:image/png;base64,${base64}`);
    await tapSemantics(page, 'Paste photo');
    expect((await waitPhotoImportOutcome(page)).kind).toBe('rendered');
  });

  test('picker rejects a declared non-image payload with unsupported-format state @portable', async ({ page }) => {
    await openPhotoStudio(page);
    const chooserPromise = page.waitForEvent('filechooser');
    await tapSemantics(page, 'Import image');
    const chooser = await chooserPromise;
    await chooser.setFiles({ name: 'not-an-image.txt', mimeType: 'text/plain', buffer: Buffer.from('not an image') });
    const outcome = await waitPhotoImportOutcome(page, 15_000);
    expect(outcome.kind).toBe('rejected');
    expect(outcome.signal).toContain('rejected:unsupportedFormat');
    await expect(page.getByText('Replace image', { exact: true })).toHaveCount(0);
  });
});
