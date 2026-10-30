import { defineConfig, type ReporterDescription } from '@playwright/test';
const reporter: ReporterDescription[] = [['list'], ['html', { outputFolder: 'generic-responsive-report', open: 'never' }]];
if (process.env.PLAYWRIGHT_JUNIT_OUTPUT_FILE) reporter.push(['junit']);
// Dedicated production-build contract; never multiply through portable projects.
export default defineConfig({
  testDir: './focused', testMatch: 'generic_responsive.spec.ts',
  fullyParallel: true, workers: 2, retries: 0, forbidOnly: true,
  timeout: 90_000, expect: { timeout: 5_000 },
  outputDir: 'generic-responsive-results',
  reporter,
  use: { browserName: 'chromium', baseURL: process.env.FLUTTER_WEB_BASE_URL || 'http://localhost:8080',
    deviceScaleFactor: 1, screenshot: 'only-on-failure', trace: 'retain-on-failure' },
  projects: [
    { name: 'wide', use: { viewport: { width: 1180, height: 757 } } },
    { name: 'compact', use: { viewport: { width: 390, height: 500 } } },
  ],
});
