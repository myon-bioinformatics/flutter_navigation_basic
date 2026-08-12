import { test, expect } from '@playwright/test';
import { waitForFlutter, navigateToHub } from '../utils/helpers';

test.describe('Hub Screen Navigation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
  });

  test('home screen loads and shows Hub button', async ({ page }) => {
    await expect(page.getByText('Screen1', { exact: false })).toBeVisible();
    await expect(page.getByText('Navigation Hub', { exact: false })).toBeVisible();
  });

  test('navigates to hub from home', async ({ page }) => {
    await navigateToHub(page);
    await expect(page.getByText('Navigation Hub', { exact: false })).toBeVisible();
  });

  test('hub shows 198 screens in grid mode', async ({ page }) => {
    await navigateToHub(page);
    // Grid is the default mode
    const items = page.locator('[key^="screen-grid-"]');
    await expect(items.first()).toBeVisible();
  });

  test('hub toggles between grid and list mode', async ({ page }) => {
    await navigateToHub(page);
    // Switch to list
    await page.getByTitle('List view').click();
    await waitForFlutter(page);
    const listItems = page.locator('[key^="screen-item-"]');
    await expect(listItems.first()).toBeVisible();

    // Switch back to grid
    await page.getByTitle('Grid view').click();
    await waitForFlutter(page);
    const gridItems = page.locator('[key^="screen-grid-"]');
    await expect(gridItems.first()).toBeVisible();
  });

  test('hub search filters screens', async ({ page }) => {
    await navigateToHub(page);
    const searchBox = page.getByPlaceholder('Search screens…');
    await searchBox.fill('Push');
    await waitForFlutter(page);
    // After filtering, fewer items should be visible
    await expect(page.getByText('BasicPush', { exact: false })).toBeVisible();
  });

  test('hub search with no results shows empty state', async ({ page }) => {
    await navigateToHub(page);
    const searchBox = page.getByPlaceholder('Search screens…');
    await searchBox.fill('zzz_nonexistent_zzz');
    await waitForFlutter(page);
    await expect(page.getByText('No screens found', { exact: false })).toBeVisible();
  });

  test('hub has Home FAB button', async ({ page }) => {
    await navigateToHub(page);
    await expect(page.getByText('Home')).toBeVisible();
  });

  test('hub Home FAB navigates back to home', async ({ page }) => {
    await navigateToHub(page);
    await page.getByText('Home').click();
    await waitForFlutter(page);
    await expect(page.getByText('Screen1', { exact: false })).toBeVisible();
  });
});
