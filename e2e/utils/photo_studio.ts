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
  const result = page.getByText(/photo-import-result (?:success|rejected):/, {
    exact: false,
  });
  try {
    await result.waitFor({ state: 'visible', timeout });
    const signal = (await result.getAttribute('aria-label')) ?? (await result.innerText());
    if (signal.includes('photo-import-result success:')) {
      return { kind: 'rendered', signal };
    }
    if (signal.includes('photo-import-result rejected:')) {
      return { kind: 'rejected', signal };
    }
    return { kind: 'timeout', signal: null };
  } catch {
    return { kind: 'timeout', signal: null };
  }
}
