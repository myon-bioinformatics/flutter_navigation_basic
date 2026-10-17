import { test, expect } from '../utils/observed_test';
import type { Page } from '@playwright/test';
import fs from 'node:fs';
import { createHash } from 'node:crypto';
import { openPhotoStudio, waitPhotoImportOutcome } from '../utils/photo_studio';
import { tapSemantics, waitForFlutter } from '../utils/helpers';
import { press } from '../utils/interaction.mjs';

// This crosses the *published* Ironmate UI and the locally built Flutter Web UI.
// Keep the committed-fixture tests in photo_studio_ingress.spec.ts independent.
const studioUrl = 'https://myon-bioinformatics.github.io/Ironmate/';
const maxInputBytes = 32 * 1024 * 1024;
const pngSignature = '89504e470d0a1a0a';
const sha256 = (bytes: Buffer) => createHash('sha256').update(bytes).digest('hex');

// Known geometry, not a pre-encoded PNG: published Ironmate must render it.
// The lower-right quadrant stays transparent through both import paths.
const scene = {
  schema: 'ironmate-image-studio/1',
  width: 96,
  height: 72,
  background: 'none',
  layers: [
    { id: 'red', kind: 'rect', name: 'red', x: 0, y: 0, w: 48, h: 36,
      rotation: 0, opacity: 1, fill: '#FF0000', stroke: 'none', strokeWidth: 0 },
    { id: 'green', kind: 'rect', name: 'green', x: 48, y: 0, w: 48, h: 36,
      rotation: 0, opacity: 1, fill: '#00FF00', stroke: 'none', strokeWidth: 0 },
    { id: 'blue', kind: 'rect', name: 'blue', x: 0, y: 36, w: 48, h: 36,
      rotation: 0, opacity: 1, fill: '#0000FF', stroke: 'none', strokeWidth: 0 },
  ],
};
const expectedPixels = [
  [255, 0, 0, 255],
  [0, 255, 0, 255],
  [0, 0, 255, 255],
  [0, 0, 0, 0],
];

function checkPngHeader(bytes: Buffer, width: number, height: number) {
  expect(bytes.subarray(0, 8).toString('hex')).toBe(pngSignature);
  expect([bytes.readUInt32BE(16), bytes.readUInt32BE(20)]).toEqual([width, height]);
}

async function decodedSamples(page: Page, dataUri: string) {
  return page.evaluate(async (uri) => {
    const bitmap = await createImageBitmap(await (await fetch(uri)).blob());
    try {
      const canvas = new OffscreenCanvas(bitmap.width, bitmap.height);
      const ctx = canvas.getContext('2d');
      if (!ctx) throw new Error('2D canvas unavailable');
      ctx.drawImage(bitmap, 0, 0);
      const points = [
        [0.125, 0.125], [0.875, 0.125], [0.125, 0.875], [0.875, 0.875],
      ];
      return points.map(([nx, ny]) =>
        Array.from(ctx.getImageData(
          Math.floor(nx * bitmap.width), Math.floor(ny * bitmap.height), 1, 1,
        ).data));
    } finally {
      bitmap.close();
    }
  }, dataUri);
}

test.describe('Published Ironmate → Flutter Web PNG handoff', () => {
  test('transparent and 2x PNG survive UI copy, photo paste and shelf resize @portable @chromium-clipboard',
    { lock: 'system-clipboard' }, async ({ page, context, browserName, baseURL }) => {
      test.skip(browserName !== 'chromium' || test.info().project.name !== 'chromium',
        'Actual Clipboard API handoff is Chromium desktop Web evidence only');
      test.setTimeout(120_000);
      await context.grantPermissions(['clipboard-read', 'clipboard-write']);
      const source = await context.newPage();
      const receipts: Record<string, unknown>[] = [];

      for (const { scale, format } of [
        { scale: 1, format: 'dataUri' },
        { scale: 2, format: 'base64' },
      ] as const) {
        await source.goto(studioUrl);
        await source.waitForFunction(() => Boolean((window as any).IronmateStudio));
        await source.locator('#open').setInputFiles({
          name: 'handoff-scene.json',
          mimeType: 'application/json',
          buffer: Buffer.from(JSON.stringify(scene)),
        });
        await expect(source.locator('#size-note')).toHaveText('96 × 72');
        await source.evaluate(() => (window as any).IronmateStudio.ready);
        await expect(source.locator('#error')).not.toBeVisible();
        await source.locator('#export-scale').selectOption(String(scale));

        // Download from the actual UI, then demand Base64 is exactly the same PNG.
        const downloadPromise = source.waitForEvent('download');
        await source.locator('#png').click();
        const download = await downloadPromise;
        const original = fs.readFileSync(await download.path());
        const width = 96 * scale, height = 72 * scale;
        checkPngHeader(original, width, height);
        expect(original.length).toBeLessThanOrEqual(maxInputBytes);
        fs.writeFileSync(test.info().outputPath('ironmate-' + scale + 'x.png'), original);

        await source.locator('#base64').click();
        await expect(source.locator('#base64-dialog')).toBeVisible();
        await source.locator('#base64-mode').selectOption(format);
        const exportedText = await source.locator('#base64-text').inputValue();
        const raw = format === 'dataUri'
          ? exportedText.replace(/^data:image\/png;base64,/, '')
          : exportedText;
        if (format === 'dataUri') expect(exportedText).toMatch(/^data:image\/png;base64,/);
        else expect(exportedText).toMatch(/^[A-Za-z0-9+/]+={0,2}$/);
        expect(raw.length % 4).toBe(0);
        expect(Buffer.from(raw, 'base64')).toEqual(original);

        await source.locator('#copy-base64').click();
        await expect(source.locator('#base64-status')).toContainText('コピーしました');
        expect(await source.evaluate(() => navigator.clipboard.readText())).toBe(exportedText);

        await page.bringToFront();
        await openPhotoStudio(page);
        // The clipboard has been written by published Ironmate, not by a fixture helper.
        expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(exportedText);
        await tapSemantics(page, 'Paste photo');
        const outcome = await waitPhotoImportOutcome(page);
        expect(outcome.kind).toBe('rendered');
        expect(outcome.signal).toContain(width + 'x' + height);
        await expect(page.getByText('Replace image', { exact: true })).toBeVisible();
        await page.screenshot({ path: test.info().outputPath('flutter-photo-' + scale + 'x.png') });

        await page.goto(new URL('#/core/clipboard-shelf', baseURL!).href);
        await waitForFlutter(page);
        await tapSemantics(page, 'Paste Base64 image');
        await expect(page.getByRole('button', { name: 'Remove', exact: true })).toBeVisible();
        await expect(page.getByRole('group', { name: /image\/png · \d+ bytes/ })).toBeVisible();
        await expect(page.getByText(/ImageDescriptor.*not supported|Image preview is unavailable/)).toHaveCount(0);
        expect(await decodedSamples(page, 'data:image/png;base64,' + raw)).toEqual(expectedPixels);

        const copy = page.getByRole('button', { name: 'Copy image as Base64 · 2/3', exact: true });
        await expect(copy).toBeEnabled();
        await press(page, copy);
        await expect(page.getByText(/Resized to 2\/3, encoded as PNG Base64/)).toBeVisible();
        const resizedText = await page.evaluate(() => navigator.clipboard.readText());
        expect(resizedText).toMatch(/^data:image\/png;base64,/);
        const resized = Buffer.from(resizedText.slice('data:image/png;base64,'.length), 'base64');
        const expectedWidth = Math.round(width * 2 / 3);
        const expectedHeight = Math.round(height * 2 / 3);
        checkPngHeader(resized, expectedWidth, expectedHeight);
        expect(resized).not.toEqual(original); // Re-encoded resize is intentional.
        expect(await decodedSamples(page, resizedText)).toEqual(expectedPixels);
        fs.writeFileSync(test.info().outputPath('flutter-resized-' + scale + 'x.png'), resized);
        await page.screenshot({ path: test.info().outputPath('flutter-shelf-' + scale + 'x.png') });

        receipts.push({
          scale, clipboardFormat: format, original: { width, height, bytes: original.length, sha256: sha256(original) },
          resized: { width: expectedWidth, height: expectedHeight, bytes: resized.length, sha256: sha256(resized) },
          photoOutcome: outcome.signal, samples: expectedPixels,
        });

        if (scale === 2) {
          // Deliberately corrupt only the MIME declaration of a real Ironmate export.
          // This must NOT silently accept PNG bytes as JPEG.
          await page.evaluate(text => navigator.clipboard.writeText(text),
            'data:image/jpeg;base64,' + raw);
          await openPhotoStudio(page);
          await tapSemantics(page, 'Paste photo');
          const rejected = await waitPhotoImportOutcome(page);
          expect(rejected.kind).toBe('rejected');
          expect(rejected.signal).toContain('rejected:decodeFailed');
        }
      }
      const asset = await source.request.get(new URL('studio.js', studioUrl).href);
      expect(asset.ok()).toBeTruthy();
      fs.writeFileSync(test.info().outputPath('handoff-receipt.json'), JSON.stringify({
        scope: 'Chromium desktop Web, not Android/iOS physical hardware',
        producer: studioUrl,
        producerStudioJsSha256: sha256(Buffer.from(await asset.body())),
        flutterSha: process.env.GITHUB_SHA ?? 'local',
        maxInputBytes,
        cases: receipts,
      }, null, 2));
      await source.close();
    });
});
