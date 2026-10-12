import { test, expect } from '@playwright/test';
import { writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { waitForFlutter } from '../utils/helpers';

// Controls are immediately available after Flutter loads; fail with a useful
// locator error instead of spending the full test timeout on a missing action.
test.use({ actionTimeout: 5_000 });

const pages: Array<[string, boolean]> = [
  ['/', true], ['/hub', true], ['/core/clipboard-shelf', false],
  ['/tools/time/now-timeline', false], ['/tools/location/coordinates', false],
  ['/tools/media/photo-studio', true], ['/tools/http/request-draft', true],
  ['/examples/ui-showcase', true], ['/examples/composition-generator', false],
  ['/examples/irony-generator', false], ['/examples/external-integration/mcp', false],
  ['/screen6', true],
];

for (const [route, requiresSecondary] of pages) {
  test(`shared header ${route} exports measured JSON @portable`, async ({ page }, testInfo) => {
    await page.goto(`/#${route}`);
    await waitForFlutter(page);
    const node = (id: string) => page.locator(`[flt-semantics-identifier="${id}"]`);
    const title = node('shared-header-title');
    await expect(title).toBeVisible();
    const ids = ['shared-header-title', 'shared-header-home', 'shared-header-favorite', 'shared-header-menu'];
    if (requiresSecondary) ids.push('shared-header-secondary');
    const boxes: Record<string, unknown> = {};
    for (const id of ids) {
      await expect(node(id)).toHaveCount(1);
      await expect(node(id)).toBeVisible();
      boxes[id] = await node(id).boundingBox();
    }
    const snapshot = { schemaVersion: 1, route, requiresSecondary, title: await title.innerText(), viewport: page.viewportSize(), boxes };
    const output = testInfo.outputPath('header-contract.json');
    writeFileSync(output, JSON.stringify(snapshot, null, 2));
    await testInfo.attach('header-contract', { path: output, contentType: 'application/json' });
    const oracle = spawnSync('python3', ['-S', '../tool/python/header_contracts.py', output], { encoding: 'utf8' });
    expect(oracle.error, String(oracle.error)).toBeUndefined();
    expect(oracle.status, oracle.stdout + oracle.stderr).toBe(0);
    await page.getByRole('button', { name: 'Favorite this page', exact: true }).click();
    await expect(page.getByRole('button', { name: 'Remove favorite', exact: true })).toBeVisible();
    await page.getByRole('button', { name: 'Remove favorite', exact: true }).click();
    await page.screenshot({ path: testInfo.outputPath('shared-header.png') });
    await page.getByRole('button', { name: 'Menu', exact: true }).click();
    await expect(page.getByText('Language', { exact: true })).toBeVisible();
  });
}
