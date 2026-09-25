import { type Page } from '@playwright/test';
import path from 'node:path';
import { waitForFlutter } from './helpers';

export const photoStudioRoute = '/#/tools/media/photo-studio';
export const photoStudioFixtureDir = path.resolve(
  process.cwd(),
  '../test/fixtures/photo_studio/import_compat',
);

export type PhotoImportOutcome = 'rendered' | 'rejected' | 'timeout';

export async function openPhotoStudio(page: Page) {
  await page.goto(photoStudioRoute);
  await waitForFlutter(page);
}

export async function clickPhotoStudioAction(page: Page, label: string) {
  const button = page.getByText(label, { exact: true });
  await button.evaluate((element) => (element as HTMLElement).click());
}

export async function pickPhotoFixture(page: Page, fileName: string) {
  const chooserPromise = page.waitForEvent('filechooser');
  await clickPhotoStudioAction(page, 'Import image');
  const chooser = await chooserPromise;
  await chooser.setFiles(path.join(photoStudioFixtureDir, fileName));
}

export async function waitPhotoImportOutcome(
  page: Page,
  timeout = 10_000,
): Promise<PhotoImportOutcome> {
  const rendered = page.getByText('Replace image', { exact: true });
  const rejected = page.getByText(
    'That image format could not be decoded.',
    { exact: true },
  );
  return Promise.race<PhotoImportOutcome>([
    rendered.waitFor({ state: 'visible', timeout }).then(() => 'rendered'),
    rejected.waitFor({ state: 'visible', timeout }).then(() => 'rejected'),
    page.waitForTimeout(timeout + 100).then(() => 'timeout'),
  ]);
}
