import { test, expect } from '@playwright/test';

// @portable: self-contained real-browser proof of the shared CLI adapter.
test('@portable shared CLI launches browser and observes asynchronous DOM updates', async ({ page }) => {
  await page.goto('data:text/html,<button id="go">Start</button><output id="result">idle</output>');
  await page.locator('#go').evaluate((button) => {
    button.addEventListener('click', () => {
      setTimeout(() => {
        document.querySelector('#result')!.textContent = 'completed';
      }, 25);
    });
  });
  await page.getByRole('button', { name: 'Start' }).click();
  await expect(page.locator('#result')).toHaveText('completed');
});
