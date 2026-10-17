// Independent page/context fixtures; schedule cases across bounded workers.
test.describe.configure({ mode: 'parallel' });
import { test, expect } from '../utils/observed_test';
import fs from 'node:fs';
import path from 'node:path';
import {
  openPhotoStudio,
  pickPhotoFixture,
  waitPhotoImportOutcome,
} from '../utils/photo_studio';
import { tapSemantics, waitForFlutter } from '../utils/helpers';
import { press } from '../utils/interaction.mjs';

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

  test('paste text data URL reaches the same success state @portable @chromium-clipboard', { lock: 'system-clipboard' }, async ({ page, context, browserName }) => {
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

test.describe('Clipboard image bridge', () => {
  test('photo picker resizes PNG and displays a preview @portable', async ({ page, baseURL }) => {
    await page.goto(new URL('#/core/clipboard-shelf', baseURL!).href);
    await waitForFlutter(page);
    const chooserPromise = page.waitForEvent('filechooser');
    await tapSemantics(page, 'Choose photo');
    await (await chooserPromise).setFiles(pngFixture);
    await expect(page.getByRole('button', { name: 'Remove', exact: true })).toBeVisible();
    await expect(page.getByRole('group', { name: /image\/png · \d+ bytes/ })).toBeVisible();
    await expect(page.getByText(/ImageDescriptor.*not supported|Image preview is unavailable/)).toHaveCount(0);
    await page.screenshot({ path: test.info().outputPath('clipboard-image-preview.png') });
  });

  test('Base64 paste, PNG resize, copy and preview round trip @portable @chromium-clipboard', { lock: 'system-clipboard' }, async ({ page, context, browserName, baseURL }) => {
    test.skip(browserName !== 'chromium', 'Real clipboard permissions are exercised in Chromium');
    await context.grantPermissions(['clipboard-read', 'clipboard-write']);
    await page.goto(new URL('#/core/clipboard-shelf', baseURL!).href);
    await waitForFlutter(page);
    await page.evaluate(value => navigator.clipboard.writeText(value),
      `data:image/png;base64,${fs.readFileSync(pngFixture).toString('base64')}`);
    await tapSemantics(page, 'Paste Base64 image');
    await expect(page.getByRole('button', { name: 'Remove', exact: true })).toBeVisible();
    const copy = page.getByRole('button', { name: 'Copy image as Base64 · 2/3', exact: true });
    await expect(copy).toBeEnabled();
    await press(page, copy);
    await expect(page.getByText(/Resized to 2\/3, encoded as PNG Base64/)).toBeVisible();
    const text = await page.evaluate(() => navigator.clipboard.readText());
    expect(text).toMatch(/^data:image\/png;base64,/);
    const png = Buffer.from(text.split(',')[1], 'base64');
    expect(png.subarray(0, 8).toString('hex')).toBe('89504e470d0a1a0a');
    expect([png.readUInt32BE(16), png.readUInt32BE(20)]).toEqual([43, 21]);
    const corners = await page.evaluate(async value => {
      const bitmap = await createImageBitmap(await (await fetch(value)).blob());
      try {
        const canvas = new OffscreenCanvas(bitmap.width, bitmap.height);
        const ctx = canvas.getContext('2d')!;
        ctx.drawImage(bitmap, 0, 0);
        return [[0, 0], [42, 0], [0, 20], [42, 20]].map(([x, y]) =>
          Array.from(ctx.getImageData(x, y, 1, 1).data));
      } finally { bitmap.close(); }
    }, text);
    expect(corners).toEqual([[255, 0, 0, 255], [0, 255, 0, 255], [0, 0, 255, 255], [255, 255, 0, 255]]);
    await press(page, page.getByRole('button', { name: 'Remove', exact: true }));
    await expect(page.getByRole('button', { name: 'Remove', exact: true })).toHaveCount(0);
    await tapSemantics(page, 'Paste Base64 image');
    await expect(page.getByRole('button', { name: 'Remove', exact: true })).toBeVisible();
    await expect(page.getByText(/Parsed image\/png from Base64/)).toBeVisible();
  });
});
