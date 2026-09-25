import { test, expect, type Page } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import { waitForFlutter } from '../utils/helpers';

const route = '/#/tools/media/photo-studio';
const fixtureDir = path.resolve(
  process.cwd(),
  '../test/fixtures/photo_studio/import_compat',
);

type FormatSupport = 'supported' | 'unsupported' | 'browser-dependent';

const formatRegistry = [
  { label: 'PNG', fileName: 'png_opaque_64x32.png', support: 'supported' },
  { label: 'JPEG baseline', fileName: 'jpeg_baseline_markers_64x32.jpg', support: 'supported' },
  { label: 'JPEG progressive', fileName: 'jpeg_progressive_markers_64x32.jpg', support: 'supported' },
  { label: 'WebP lossy', fileName: 'webp_lossy_64x32.webp', support: 'supported' },
  { label: 'WebP lossless', fileName: 'webp_lossless_64x32.webp', support: 'supported' },
  { label: 'GIF still', fileName: 'gif_still_1x1.gif', support: 'supported' },
] satisfies ReadonlyArray<{
  label: string;
  fileName: string;
  support: FormatSupport;
}>;

function diag(stage: string, fields: Record<string, unknown> = {}) {
  console.log('[photo-studio-format-matrix]', JSON.stringify({ stage, ...fields }));
}

function attachBrowserDiagnostics(page: Page) {
  page.on('console', (message) => {
    console.log('[browser-console]', message.type(), message.text());
  });
  page.on('pageerror', (error) => {
    console.log('[browser-pageerror]', error.message);
  });
}

async function openPhotoStudio(page: Page) {
  diag('1/4 navigation:start', { route });
  await page.goto(route);
  await waitForFlutter(page);
  diag('1/4 navigation:ready', { route });
}

async function pickFixture(page: Page, label: string, fileName: string) {
  const fixturePath = path.join(fixtureDir, fileName);
  const exists = fs.existsSync(fixturePath);
  diag('2/4 fixture:classified', {
    label,
    fileName,
    exists,
    bytes: exists ? fs.statSync(fixturePath).size : null,
  });
  if (!exists) {
    throw new Error(`[photo-studio-format-matrix] missing fixture: ${fixturePath}`);
  }

  const chooserPromise = page.waitForEvent('filechooser');
  const importButton = page.getByText('Import image', { exact: true });
  await importButton.evaluate((element) => (element as HTMLElement).click());
  const chooser = await chooserPromise;
  diag('3/4 picker:acquired', { label, fileName });
  await chooser.setFiles(fixturePath);
  diag('3/4 picker:file-set', { label, fileName });
}

async function expectImportResult(page: Page, label: string, fileName: string) {
  diag('4/4 render:waiting', { label, fileName });
  try {
    await expect(page.getByText('Image loaded', { exact: true })).toBeVisible({
      timeout: 15_000,
    });
    await expect(page.getByText('Replace image', { exact: true })).toBeVisible();
    diag('4/4 render:passed', { label, fileName });
  } catch (error) {
    const visibleTexts = await page.locator('body').innerText().catch(() => '');
    diag('4/4 render:failed', {
      label,
      fileName,
      reason: error instanceof Error ? error.message.split('\n')[0] : String(error),
      bodyHasDecodeError: visibleTexts.includes('could not be decoded'),
      bodyHasImageLoaded: visibleTexts.includes('Image loaded'),
      bodyHasReplaceImage: visibleTexts.includes('Replace image'),
    });
    throw error;
  }
}

test.describe('Photo Studio portable format matrix', () => {
  for (const entry of formatRegistry) {
    test(`${entry.label} imports successfully through the web picker @portable @format-matrix`, async ({ page }) => {
      diag('case:start', entry);
      attachBrowserDiagnostics(page);
      await openPhotoStudio(page);
      await pickFixture(page, entry.label, entry.fileName);
      await expectImportResult(page, entry.label, entry.fileName);
    });
  }

  test('truncated PNG is rejected with unsupported-format state @portable @format-matrix', async ({ page }) => {
    const label = 'PNG truncated';
    const fileName = 'png_truncated.png';
    diag('case:start', { label, fileName, support: 'unsupported' });
    attachBrowserDiagnostics(page);
    await openPhotoStudio(page);
    await pickFixture(page, label, fileName);

    diag('4/4 render:waiting-rejection', { label, fileName });
    await expect(
      page.getByText('That image format could not be decoded.', { exact: true }),
    ).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText('Image loaded', { exact: true })).toHaveCount(0);
    await expect(page.getByText('Replace image', { exact: true })).toHaveCount(0);
    diag('4/4 render:rejected-as-expected', { label, fileName });
  });
});
