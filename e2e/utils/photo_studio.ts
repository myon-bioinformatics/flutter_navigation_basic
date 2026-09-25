import { type Page } from '@playwright/test';
import path from 'node:path';
import { tapSemantics, waitForFlutter } from './helpers';

export const photoStudioRoute = '/#/tools/media/photo-studio';
export const photoStudioFixtureDir = path.resolve(
  process.cwd(),
  '../test/fixtures/photo_studio/import_compat',
);

export type PhotoImportOutcome =
  | { kind: 'rendered'; signal: string }
  | { kind: 'rejected'; signal: string }
  | { kind: 'timeout'; signal: null };

export async function openPhotoStudio(page: Page) {
  await page.goto(photoStudioRoute);
  await waitForFlutter(page);
}

export async function pickPhotoFixture(page: Page, fileName: string) {
  const chooserPromise = page.waitForEvent('filechooser');
  await tapSemantics(page, 'Import image');
  const chooser = await chooserPromise;
  await chooser.setFiles(path.join(photoStudioFixtureDir, fileName));
}

export async function waitPhotoImportOutcome(
  page: Page,
  timeout = 10_000,
): Promise<PhotoImportOutcome> {
  const selector = '[flt-semantics-identifier="photo-import-result"]';
  try {
    const handle = await page.waitForFunction(
      (sel) => {
        const element = document.querySelector(sel);
        if (!element) return null;
        const signal =
          element.getAttribute('aria-valuetext') ??
          element.getAttribute('aria-label') ??
          element.getAttribute('value') ??
          element.textContent ??
          '';
        return /photo-import-result (?:success|rejected):/.test(signal)
          ? signal
          : null;
      },
      selector,
      { timeout },
    );
    const signal = (await handle.jsonValue()) as string;
    return signal.includes('photo-import-result success:')
      ? { kind: 'rendered', signal }
      : { kind: 'rejected', signal };
  } catch {
    const result = page.locator(selector);
    const diagnostic = await result
      .evaluate((element) => ({
        ariaValueText: element.getAttribute('aria-valuetext'),
        ariaLabel: element.getAttribute('aria-label'),
        value: element.getAttribute('value'),
        textContent: element.textContent,
      }))
      .catch(() => null);
    console.log(
      '[photo-import-result] timeout ' + JSON.stringify({ timeout, diagnostic }),
    );
    return { kind: 'timeout', signal: null };
  }
}
