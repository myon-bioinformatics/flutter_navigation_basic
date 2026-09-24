import { chromium, firefox, webkit } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

const args = Object.fromEntries(process.argv.slice(2).map((arg) => {
  const [key, ...rest] = arg.replace(/^--/, '').split('=');
  return [key, rest.join('=') || 'true'];
}));
const browserName = args.browser || 'chromium';
const baseURL = args.baseURL || 'http://localhost:8080';
const fixture = args.fixture;
const output = args.output || 'test-results/photo-studio-evidence.png';
const timeout = Number(args.timeout || 30000);
if (!fixture) throw new Error('missing --fixture=/path/to/image');
const engines = { chromium, firefox, webkit };
if (!engines[browserName]) throw new Error(`unsupported browser: ${browserName}`);
fs.mkdirSync(path.dirname(output), { recursive: true });
const browser = await engines[browserName].launch();
const page = await browser.newPage();
page.setDefaultTimeout(timeout);
page.on('console', (msg) => console.log(`[browser:${msg.type()}] ${msg.text()}`));
page.on('pageerror', (err) => console.error(`[browser:error] ${err.message}`));
try {
  console.log(JSON.stringify({ event: 'start', browser: browserName, baseURL, fixture, output, timeout }));
  await page.goto(`${baseURL.replace(/\/$/, '')}/#/tools/media/photo-studio`, { waitUntil: 'networkidle', timeout });
  const importButton = page.getByText('Import image', { exact: true });
  await importButton.waitFor({ state: 'visible' });
  const chooserPromise = page.waitForEvent('filechooser', { timeout });
  await importButton.click();
  const chooser = await chooserPromise;
  await chooser.setFiles(fixture);
  await page.getByText(/Image loaded/).waitFor({ state: 'visible', timeout });
  await page.screenshot({ path: output, fullPage: true });
  console.log(JSON.stringify({ event: 'success', output }));
} catch (error) {
  console.error(JSON.stringify({ event: 'failure', message: String(error) }));
  process.exitCode = 1;
} finally {
  await browser.close();
}
