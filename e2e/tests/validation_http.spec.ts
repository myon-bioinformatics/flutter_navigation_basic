import { test, expect, type Page, type Response } from '@playwright/test';
import { spawn, type ChildProcess } from 'node:child_process';
import path from 'node:path';

// The validation page is a loopback Python server, not the Flutter web build.
// This spec starts that server on an ephemeral port and drives the real form.
let server: ChildProcess | undefined;
let baseURL = '';
let dialogs: string[] = [];

function startServer(): Promise<string> {
  const script = path.resolve(__dirname, '../../python/validation_http.py');
  const child = spawn('python3', ['-S', script, '--port', '0'], {
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  server = child;
  let stderr = '';
  child.stderr?.on('data', (chunk: Buffer) => {
    stderr += chunk.toString('utf8');
  });
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      reject(new Error(`validation server did not listen\n${stderr}`));
    }, 10_000);
    let buffer = '';
    const onData = (chunk: Buffer) => {
      buffer += chunk.toString('utf8');
      const match = buffer.match(/listening (http:\/\/127\.0\.0\.1:\d+\/)/);
      if (!match) return;
      clearTimeout(timer);
      child.stdout?.off('data', onData);
      resolve(match[1]);
    };
    child.stdout?.on('data', onData);
    child.once('error', (error) => {
      clearTimeout(timer);
      reject(error);
    });
    child.once('exit', (code) => {
      clearTimeout(timer);
      reject(new Error(`validation server exited ${code} before listening\n${stderr}`));
    });
  });
}

async function stopServer(): Promise<void> {
  const child = server;
  server = undefined;
  if (!child || child.exitCode !== null) return;
  child.kill('SIGTERM');
  await new Promise<void>((resolve) => {
    const timer = setTimeout(() => {
      child.kill('SIGKILL');
      resolve();
    }, 2_000);
    child.once('exit', () => {
      clearTimeout(timer);
      resolve();
    });
  });
}

async function validate(page: Page, operation: string, value: string): Promise<Response> {
  await page.locator('#op').selectOption(operation);
  await page.locator('#value').fill(value);
  const pending = page.waitForResponse(
    (response) => response.url().endsWith('/validate') && response.request().method() === 'POST',
  );
  await page.locator('#run').click();
  return pending;
}

test.describe('Python validation page', () => {
  test.beforeAll(async () => {
    baseURL = await startServer();
  });

  test.afterAll(async () => {
    await stopServer();
  });

  test.beforeEach(async ({ page }) => {
    dialogs = [];
    page.on('dialog', async (dialog) => {
      dialogs.push(dialog.message());
      await dialog.dismiss();
    });
    await page.goto(baseURL);
    await expect(page.locator('#run')).toBeVisible();
  });

  test('valid input shows success', async ({ page }, testInfo) => {
    const response = await validate(page, 'email', 'a@example.org');
    expect(response.status()).toBe(200);
    expect(await response.json()).toEqual({ valid: true });
    const result = page.locator('#result');
    await expect(result).toContainText('"http_status": 200');
    await expect(result).toContainText('"valid": true');
    await page.screenshot({ path: testInfo.outputPath('validation-success.png'), fullPage: true });
  });

  test('invalid input shows failure', async ({ page }, testInfo) => {
    const response = await validate(page, 'email', 'not-an-email');
    expect(response.status()).toBe(200);
    expect(await response.json()).toEqual({ valid: false });
    const result = page.locator('#result');
    await expect(result).toContainText('"http_status": 200');
    await expect(result).toContainText('"valid": false');
    await page.screenshot({ path: testInfo.outputPath('validation-failure.png'), fullPage: true });
  });

  test('markup in the input stays plain text', async ({ page }, testInfo) => {
    const payload = '<img src=x onerror=alert(1)>';
    const response = await validate(page, 'email', payload);
    expect(response.status()).toBe(200);
    expect((await response.json()).valid).toBe(false);
    const result = page.locator('#result');
    await expect(result).toContainText(payload);
    await expect(result.locator('img')).toHaveCount(0);
    await expect(page.locator('img')).toHaveCount(0);
    await expect(page.locator('#value')).toHaveValue(payload);
    expect(dialogs).toEqual([]);
    await page.screenshot({ path: testInfo.outputPath('validation-plain-text.png'), fullPage: true });
  });

  test('range, regex, and form use the python validator', async ({ page }) => {
    let response = await validate(page, 'range', '10');
    expect(response.status()).toBe(200);
    expect(await response.json()).toEqual({ valid: true });

    response = await validate(page, 'range', '101');
    expect(response.status()).toBe(200);
    expect(await response.json()).toEqual({ valid: false });

    response = await validate(page, 'regex', 'abc_1');
    expect(await response.json()).toEqual({ valid: true });

    response = await validate(page, 'form', 'kept');
    expect(await response.json()).toEqual({
      valid: true,
      fields: [{ name: 'required', valid: true }],
    });
  });
});
