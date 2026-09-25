import { test, type Page } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import { openPhotoStudio, pickPhotoFixture, waitPhotoImportOutcome } from '../utils/photo_studio';

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
  { label: 'PNG truncated', fileName: 'png_truncated.png', support: 'unsupported' },
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


async function probeImportResult(
  page: Page,
  label: string,
  fileName: string,
) {
  diag('4/4 probe:waiting', { label, fileName });
  const reached = await waitPhotoImportOutcome(page);
  const visibleTexts = await page.locator('body').innerText().catch(() => '');
  diag('4/4 probe:result', {
    label,
    fileName,
    reached,
    bodyHasImageLoaded: visibleTexts.includes('Image loaded'),
    bodyHasReplaceImage: visibleTexts.includes('Replace image'),
    bodyHasDecodeError: visibleTexts.includes('could not be decoded'),
  });
  return reached;
}

test.describe('Photo Studio portable format matrix', () => {
  for (const entry of formatRegistry) {
    test(`${entry.label} @portable @format-matrix`, async ({ page }, testInfo) => {
      diag('case:start', entry);
      attachBrowserDiagnostics(page);

      let reached: string = 'navigation';
      try {
        await openPhotoStudio(page);
        reached = 'fixture';
        const fixturePath = path.join(fixtureDir, entry.fileName);
        if (!fs.existsSync(fixturePath)) throw new Error(`missing fixture: ${fixturePath}`);
        await pickPhotoFixture(page, entry.fileName);
        reached = await probeImportResult(page, entry.label, entry.fileName);
      } catch (error) {
        diag('case:probe-error', {
          label: entry.label,
          fileName: entry.fileName,
          reached,
          reason: error instanceof Error ? error.message.split('\n')[0] : String(error),
        });
      }

      const outcome = {
        label: entry.label,
        fileName: entry.fileName,
        project: testInfo.project.name,
        expected: entry.support === 'unsupported' ? 'rejected' : 'rendered',
        reached,
      };
      await testInfo.attach('format-outcome', {
        body: JSON.stringify(outcome, null, 2),
        contentType: 'application/json',
      });
      testInfo.annotations.push({ type: 'reached', description: reached });

      // Probe lane intentionally does not fail on a format mismatch. Its job is
      // to collect the complete format × project matrix in one manual run.
      // A separate smoke/contract lane may assert a stable structured signal.
      diag('case:outcome', outcome);
    });
  }
});
