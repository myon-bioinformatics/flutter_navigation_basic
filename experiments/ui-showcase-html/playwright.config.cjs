'use strict';

const path = require('node:path');
const { createRequire } = require('node:module');
const fromE2E = createRequire(path.join(__dirname, '../../e2e/package.json'));
const { defineConfig } = fromE2E('@playwright/test');
const artifacts = path.join(__dirname, '../../build/ui-showcase-comparison');

module.exports = defineConfig({
  testDir: __dirname,
  outputDir: path.join(artifacts, 'test-results'),
  fullyParallel: false,
  workers: 1,
  retries: 0,
  forbidOnly: !!process.env.CI,
  timeout: 120_000,
  expect: { timeout: 7_500 },
  reporter: [
    ['list'],
    ['html', { outputFolder: path.join(artifacts, 'html-report'), open: 'never' }],
    ['json', { outputFile: path.join(artifacts, 'playwright-results.json') }],
  ],
  use: {
    browserName: 'chromium',
    baseURL: 'http://127.0.0.1:8765',
    deviceScaleFactor: 1,
    locale: 'en-US',
    colorScheme: 'light',
    reducedMotion: 'reduce',
    hasTouch: false,
    isMobile: false,
    serviceWorkers: 'block',
    actionTimeout: 10_000,
    navigationTimeout: 45_000,
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
  },
  projects: [
    { name: 'wide-1180x757', testMatch: 'comparison.spec.cjs', use: { viewport: { width: 1180, height: 757 } } },
    { name: 'compact-390x500', testMatch: 'comparison.spec.cjs', use: { viewport: { width: 390, height: 500 } } },
    { name: 'native-responsive', testMatch: 'responsive.spec.cjs', use: { viewport: { width: 320, height: 500 } } },
  ],
  webServer: {
    command: `node ${JSON.stringify(path.join(__dirname, 'server.cjs'))}`,
    url: 'http://127.0.0.1:8765',
    reuseExistingServer: !process.env.CI,
    timeout: 15_000,
  },
});
