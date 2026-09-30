import { test, expect, type Locator } from '@playwright/test';
import fs from 'node:fs';
import { createHash } from 'node:crypto';
import { waitForFlutter } from '../utils/helpers';

// Success evidence, independent of pixel baselines and failure-only screenshots.
test('canonical Home and Build diagnostics evidence @portable', async ({ page }, testInfo) => {
  test.setTimeout(90_000);
  const canonical = JSON.parse(fs.readFileSync('../build/diagnostics/repository/repository-metadata.json', 'utf8'));
  expect(canonical.head.sha).toBe(process.env.EXPECTED_SHA);
  expect(canonical.head.timestamp).toBeTruthy();
  expect(canonical.generated_at).toBeTruthy();
  const response = await page.request.get('/assets/assets/diagnostics/build_metadata.json');
  expect(response.ok()).toBeTruthy();
  const metadata = await response.json();
  expect(metadata.repository.revision.sha).toBe(canonical.head.sha);
  expect(metadata.repository.revision.committedAt).toBe(canonical.head.timestamp);
  expect(metadata.repository.revision.generatedAt).toBe(canonical.generated_at);
  expect(metadata.measurement.platform).toBe('web');
  await page.goto('/');
  await waitForFlutter(page, 30_000);
  const committed = page.getByText(`Committed: ${canonical.head.timestamp}`, { exact: true });
  await expect(committed.first()).toBeVisible();
  await expect(page.getByRole('button', { name: new RegExp(`^SHA: ${canonical.head.sha}`) })).toBeVisible();
  const captures: { file: string; bytes: number; sha256: string }[] = [];
  async function capture(file: string) {
    const output = testInfo.outputPath(file);
    const png = await page.screenshot({ path: output, animations: 'disabled' });
    expect(png.subarray(0, 8).toString('hex')).toBe('89504e470d0a1a0a');
    expect(png.length).toBeGreaterThan(1000);
    captures.push({ file, bytes: png.length, sha256: createHash('sha256').update(png).digest('hex') });
    await testInfo.attach(file, { path: output, contentType: 'image/png' });
  }
  await capture('home.png');
  const generated = page.getByText('Metadata generated ' + canonical.generated_at);
  const buildDiagnostics = page.getByText('Build diagnostics');
  const buildCommit = page.getByText('Commit ' + canonical.head.short_sha);
  async function intersectsViewport(locator: Locator) {
    const box = await locator.boundingBox();
    const viewport = page.viewportSize();
    return Boolean(
      box &&
        viewport &&
        box.width > 0 &&
        box.height > 0 &&
        box.x < viewport.width &&
        box.x + box.width > 0 &&
        box.y < viewport.height &&
        box.y + box.height > 0,
    );
  }
  // Flutter paints a scrollable canvas; move the real viewport, not the
  // accessibility nodes. Mobile WebKit does not support mouse.wheel.
  for (let attempt = 0; attempt < 20 && !(await intersectsViewport(generated)); attempt++) {
    if (testInfo.project.name === 'mobile-webkit') {
      await page.keyboard.press('End');
    } else {
      await page.mouse.move(Math.floor(page.viewportSize()!.width / 2), Math.floor(page.viewportSize()!.height / 2));
      await page.mouse.wheel(0, 400);
    }
    await page.waitForTimeout(150);
  }
  await expect(generated).toBeVisible();
  expect(await intersectsViewport(generated), 'Metadata generated must be on screen').toBe(true);
  await expect(committed.last()).toBeVisible();
  expect(await intersectsViewport(committed.last()), 'Build commit timestamp must be on screen').toBe(true);
  await expect(buildDiagnostics).toBeVisible();
  await expect(buildCommit).toBeVisible();
  expect(await intersectsViewport(buildCommit), 'Build commit SHA must be on screen').toBe(true);
  await capture('build-diagnostics.png');
  expect(captures[0].sha256, 'Build screenshot must differ from the Home viewport').not.toBe(captures[1].sha256);
  expect(captures[1].sha256).not.toBe(captures[0].sha256);
  const manifest = testInfo.outputPath('evidence.json');
  fs.writeFileSync(manifest, JSON.stringify({
    sha: canonical.head.sha,
    committed_at: canonical.head.timestamp,
    generated_at: canonical.generated_at,
    project: testInfo.project.name,
    viewport: page.viewportSize(),
    browser_version: page.context().browser()!.version(),
    captures,
  }, null, 2));
  await testInfo.attach('evidence.json', { path: manifest, contentType: 'application/json' });
});
