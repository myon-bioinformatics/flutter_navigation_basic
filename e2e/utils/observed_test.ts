/** Capture receipts in the existing browser lane; replay needs Python stdlib only. */
import { test as base, expect } from '@playwright/test';
import fs from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { inventory } from './interaction.mjs';

const hash = (bytes: Buffer) => createHash('sha256').update(bytes).digest('hex');
const fixture = path.resolve(process.cwd(), '../test/fixtures/photo_studio/import_compat/png_opaque_64x32.png');

export const test = base.extend<{ observation: void }>({
  observation: [async ({ page, browser, browserName }, use, info) => {
    const errors: { kind: string; message: string }[] = [];
    const record = (kind: string, message: string) => {
      if (errors.length < 100) errors.push({ kind, message: message.slice(0, 1000) });
    };
    page.on('pageerror', error => record('pageerror', error.message));
    page.on('console', message => {
      if (['warning', 'error'].includes(message.type())) record(message.type(), message.text());
    });
    page.on('requestfailed', request => {
      const url = new URL(request.url());
      record('requestfailed', `${url.origin}${url.pathname}: ${request.failure()?.errorText}`);
    });
    await use();
    if (info.status === 'skipped') return;
    const captureErrors: string[] = [];
    let display: unknown = null;
    let revision: string | null = null;
    let screenshot: { file: string; sha256: string; bytes: number } | null = null;
    try {
      const elements = await inventory(page, {
        selector: '[flt-semantics-identifier], [role="button"]', limit: 2000,
      });
      if (elements.truncated) throw new Error('control inventory truncated');
      display = {
        ...await page.evaluate(() => ({
          viewport: { width: innerWidth, height: innerHeight },
          device_scale_factor: devicePixelRatio, user_agent: navigator.userAgent,
        })),
        controls: elements.elements
          .filter((node: { aria_label: string | null }) => !/^(SHA:|Commit )/.test(node.aria_label || ''))
          .map((node: { id: string | null; aria_label: string | null; text: string; tag: string;
              box: { x: number; y: number; width: number; height: number }; in_viewport: boolean }) => ({
            label: node.id || node.aria_label || node.text || node.tag,
            visible: node.in_viewport, box: node.box,
          })),
      };
      const url = new URL('assets/assets/diagnostics/build_metadata.json', info.project.use.baseURL!);
      const response = await page.request.get(url.href, { timeout: 5000 });
      if (!response.ok()) throw new Error(`build metadata: HTTP ${response.status()}`);
      revision = (await response.json()).repository?.revision?.sha ?? null;
      const file = 'web-observation.png';
      const bytes = await page.screenshot({ path: info.outputPath(file), animations: 'disabled', timeout: 5000 });
      screenshot = { file, sha256: hash(bytes), bytes: bytes.length };
      await info.attach(file, { path: info.outputPath(file), contentType: 'image/png' });
    } catch (error) {
      captureErrors.push(String(error).slice(0, 1000));
    }
    const receipt = {
      schema: 'flutter-web-observation/1', captured_at: new Date().toISOString(),
      scope: 'historical-web-observation',
      test: info.titlePath.join(' > '), project: info.project.name,
      status: info.status, expected_status: info.expectedStatus, retry: info.retry,
      url: page.url(), build_sha: revision,
      run: { id: process.env.GITHUB_RUN_ID ?? null, attempt: process.env.GITHUB_RUN_ATTEMPT ?? null },
      runtime: { browser: browserName, browser_version: browser.version(), node: process.version,
        platform: process.platform, display },
      fixture: info.file.endsWith('photo_studio_ingress.spec.ts') && !info.title.includes('non-image')
        ? { file: path.basename(fixture), sha256: hash(fs.readFileSync(fixture)) } : null,
      catalogue: process.env.FLUTTER_WEB_ROUTES ? JSON.parse(process.env.FLUTTER_WEB_ROUTES) : null,
      screenshot, errors, capture_errors: captureErrors,
    };
    const output = info.outputPath('web-observation.json');
    fs.writeFileSync(output, JSON.stringify(receipt, null, 2) + '\n');
    await info.attach('web-observation.json', { path: output, contentType: 'application/json' });
  }, { auto: true }],
});
export { expect };
