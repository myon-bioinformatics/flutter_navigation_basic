import { test, expect, type Page } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import { openPhotoStudio, pickPhotoFixture, waitPhotoImportOutcome } from '../utils/photo_studio';

const fixtureDir = path.resolve(
  process.cwd(),
  '../test/fixtures/photo_studio/import_compat',
);

type FormatSupport = 'supported' | 'unsupported' | 'browser-dependent';

const formatRegistry = [
  { label: 'PNG', fileName: 'png_opaque_64x32.png', support: 'supported', expectedSize: '64x32' },
  { label: 'JPEG baseline', fileName: 'jpeg_baseline_markers_64x32.jpg', support: 'supported', expectedSize: '64x32' },
  { label: 'JPEG progressive', fileName: 'jpeg_progressive_markers_64x32.jpg', support: 'supported', expectedSize: '64x32' },
  { label: 'WebP lossy', fileName: 'webp_lossy_64x32.webp', support: 'supported', expectedSize: '64x32' },
  { label: 'WebP lossless', fileName: 'webp_lossless_64x32.webp', support: 'supported', expectedSize: '64x32' },
  { label: 'GIF still', fileName: 'gif_still_1x1.gif', support: 'supported', expectedSize: '1x1' },
  { label: 'PNG truncated', fileName: 'png_truncated.png', support: 'unsupported', expectedSize: null },
] satisfies ReadonlyArray<{
  label: string;
  fileName: string;
  support: FormatSupport;
  expectedSize: string | null;
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
  const outcome = await waitPhotoImportOutcome(page);
  const reached = outcome.kind;
  const visibleTexts = await page.locator('body').innerText().catch(() => '');
  diag('4/4 probe:result', {
    label,
    fileName,
    reached,
    signal: outcome.signal,
    bodyHasImageLoaded: visibleTexts.includes('Image loaded'),
    bodyHasReplaceImage: visibleTexts.includes('Replace image'),
    bodyHasDecodeError: visibleTexts.includes('could not be decoded'),
  });
  return { reached, signal: outcome.signal };
}

test.describe('Photo Studio portable format matrix', () => {
  for (const entry of formatRegistry) {
    test(`${entry.label} @portable @format-matrix`, async ({ page }, testInfo) => {
      diag('case:start', entry);
      attachBrowserDiagnostics(page);

      let reached: string = 'navigation';
      let signal: string | null = null;
      try {
        await openPhotoStudio(page);
        reached = 'fixture';
        const fixturePath = path.join(fixtureDir, entry.fileName);
        if (!fs.existsSync(fixturePath)) throw new Error(`missing fixture: ${fixturePath}`);
        await pickPhotoFixture(page, entry.fileName);
        const probe = await probeImportResult(page, entry.label, entry.fileName);
        reached = probe.reached;
        signal = probe.signal;
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
        signal,
      };
      await testInfo.attach('format-outcome', {
        body: JSON.stringify(outcome, null, 2),
        contentType: 'application/json',
      });
      testInfo.annotations.push({ type: 'reached', description: reached });

      diag('case:outcome', outcome);

      const expected = entry.support === 'unsupported' ? 'rejected' : 'rendered';
      expect(reached).toBe(expected);
      if (entry.expectedSize != null) {
        expect(signal).not.toBeNull();
        expect(signal).toContain(`:${entry.expectedSize}`);
      }
    });
  }
});
