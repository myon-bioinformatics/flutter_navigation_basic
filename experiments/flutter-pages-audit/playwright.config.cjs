'use strict';
const path = require('node:path');
const { createRequire } = require('node:module');
const fromE2E = createRequire(path.join(__dirname, '../../e2e/package.json'));
const { defineConfig } = fromE2E('@playwright/test');
const family = require('./family-inventory.json');
if (family.caseCount !== 48 || family.contracts.length !== 24 || new Set(family.contracts.map(c=>c.route)).size !== 24) throw new Error('Expected exact 48-case family discovery');
const escape = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const output = path.resolve(process.env.AUDIT_OUTPUT || 'build/flutter-pages-audit');
module.exports = defineConfig({
  testDir: __dirname, testMatch: 'audit.spec.cjs', outputDir: path.join(output, 'cases'),
  grep: new RegExp('observe public route (' + family.contracts.map(c=>escape(c.route)).join('|') + ')$'),
  fullyParallel: true, workers: 2, retries: 0, maxFailures: 0, forbidOnly: !!process.env.CI,
  timeout: 90_000, expect: { timeout: 3_000 },
  reporter: [['list'], ['json', { outputFile: path.join(output, 'playwright-results.json') }]],
  use: {
    browserName: 'chromium', deviceScaleFactor: 1, locale: 'en-US', colorScheme: 'light',
    reducedMotion: 'reduce', hasTouch: false, isMobile: false, serviceWorkers: 'block',
    actionTimeout: 5_000, navigationTimeout: 25_000, trace: 'off', screenshot: 'off',
  },
  projects: [
    { name: 'wide-1180x757', use: { viewport: { width: 1180, height: 757 } } },
    { name: 'compact-390x500', use: { viewport: { width: 390, height: 500 } } },
  ],
});
