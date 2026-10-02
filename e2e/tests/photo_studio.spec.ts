import { test, expect } from '@playwright/test';
import {
  openPhotoStudio,
  pickPhotoFixture,
  waitPhotoImportOutcome,
} from '../utils/photo_studio';

test.describe('Photo Studio representative flow', () => {
  test.beforeEach(async ({ page }) => {
    await openPhotoStudio(page);
  });

  test('opens the canonical Photo Studio route @portable', async ({ page }) => {
    await expect(page).toHaveURL(/#\/tools\/media\/photo-studio$/);
    await expect(page.getByText('Photo Studio', { exact: true })).toBeVisible();
    await expect(page.getByText('Import image', { exact: true })).toBeVisible();
    await expect(page.getByText('Paste photo', { exact: true })).toBeVisible();
  });

  test('imports a committed PNG through the browser file picker @portable', async ({ page }) => {
    await pickPhotoFixture(page, 'png_opaque_64x32.png');
    expect((await waitPhotoImportOutcome(page)).kind).toBe('rendered');
  });
});
