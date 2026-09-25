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
        const own = document.querySelector(sel);
        const candidates = [
          own?.getAttribute('aria-valuetext'),
          own?.getAttribute('aria-label'),
          own?.getAttribute('value'),
          own?.textContent,
          ...Array.from(
            document.querySelectorAll('[aria-label*="photo-import-result"]'),
            (element) => element.getAttribute('aria-label'),
          ),
          document.body.innerText,
        ]
          .filter((value): value is string => Boolean(value))
          .join(' ');
        return /photo-import-result (?:success|rejected):[^\\s]+/.exec(candidates)?.[0] ?? null;
      },
      selector,
      { timeout },
    );
    const signal = (await handle.jsonValue()) as string;
    return signal.includes('photo-import-result success:')
      ? { kind: 'rendered', signal }
      : { kind: 'rejected', signal };
  } catch {
    const diagnostic = await page
      .evaluate((sel) => {
        const element = document.querySelector(sel);
        return {
          target: element
            ? {
                ariaValueText: element.getAttribute('aria-valuetext'),
                ariaLabel: element.getAttribute('aria-label'),
                value: element.getAttribute('value'),
                textContent: element.textContent,
              }
            : null,
          identifiers: Array.from(
            document.querySelectorAll('[flt-semantics-identifier]'),
            (node) => node.getAttribute('flt-semantics-identifier'),
          ),
          labelHit: Array.from(
            document.querySelectorAll('[aria-label*="photo-import-result"]'),
            (node) => node.getAttribute('aria-label'),
          ).slice(0, 3),
          bodyHit:
            /photo-import-result \\S+/.exec(document.body.innerText)?.[0] ?? null,
        };
      }, selector)
      .catch(() => null);
    console.log(
      '[photo-import-result] timeout ' +
        JSON.stringify({ timeout, diagnostic }),
    );
    return { kind: 'timeout', signal: null };
  }
}
