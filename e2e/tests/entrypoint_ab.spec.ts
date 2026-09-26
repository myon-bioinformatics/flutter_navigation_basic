import { test, expect } from '@playwright/test';
import path from 'node:path';
import { waitForFlutter } from '../utils/helpers';
import {
  photoStudioFixtureDir,
  photoStudioRoute,
  waitPhotoImportOutcome,
} from '../utils/photo_studio';

test('records cold Photo Studio route and picker state @entrypoint-ab', async ({ page }) => {
  const started = Date.now();
  await page.goto(photoStudioRoute);
  await waitForFlutter(page);

  const importButton = page.getByRole('button', { name: 'Import image', exact: true }).first();
  const importCount = await importButton.count();
  const importVisible = importCount > 0 ? await importButton.isVisible().catch(() => false) : false;
  const importBox = importCount > 0 ? await importButton.boundingBox().catch(() => null) : null;
  const homeMarkerCount = await page.getByText('Navigation Hub', { exact: false }).count();

  const dom = await page.evaluate(() => ({
    hash: window.location.hash,
    viewport: { width: window.innerWidth, height: window.innerHeight },
    identifiers: Array.from(
      document.querySelectorAll('[flt-semantics-identifier]'),
      (node) => node.getAttribute('flt-semantics-identifier'),
    ).filter(Boolean),
    bodySample: document.body.innerText.replace(/\s+/g, ' ').slice(0, 500),
  }));

  const screenIdentity =
    importCount > 0 ? 'photo-studio' : homeMarkerCount > 0 ? 'home' : 'unknown';

  console.log(
    '[entrypoint-ab] observation ' +
      JSON.stringify({
        entrypointLabel: process.env.ENTRYPOINT_AB_LABEL ?? null,
        entrypointTarget: process.env.ENTRYPOINT_AB_TARGET ?? null,
        screenIdentity,
        hash: dom.hash,
        importImage: {
          count: importCount,
          visible: importVisible,
          boundingBox: importBox,
        },
        homeMarkerCount,
        viewport: dom.viewport,
        identifiers: dom.identifiers,
        bodySample: dom.bodySample,
        elapsedMs: Date.now() - started,
      }),
  );

  expect(
    screenIdentity,
    'rendered screen identity after cold Photo Studio deep link',
  ).toBe('photo-studio');
  expect(importCount, 'Import image semantics button must exist').toBeGreaterThan(0);

  const chooserPromise = page.waitForEvent('filechooser');
  await importButton.evaluate((node) => (node as HTMLElement).click());
  const chooser = await chooserPromise;
  await chooser.setFiles(path.join(photoStudioFixtureDir, 'png_opaque_64x32.png'));

  const outcome = await waitPhotoImportOutcome(page);
  console.log(
    '[entrypoint-ab] picker ' +
      JSON.stringify({
        entrypointLabel: process.env.ENTRYPOINT_AB_LABEL ?? null,
        hash: await page.evaluate(() => window.location.hash),
        screenIdentity,
        outcome,
      }),
  );
  expect(outcome.kind).toBe('rendered');
});
