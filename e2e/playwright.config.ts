import { flutterWorkerBudget } from './utils/flutter_worker_policy.mjs';
import { defineConfig, devices, type ReporterDescription } from '@playwright/test';

// JUnit is opt-in: without an output file the junit reporter would print XML to
// stdout. CI sets PLAYWRIGHT_JUNIT_OUTPUT_FILE per invocation.
const reporter: ReporterDescription[] = [
  ['html', { outputFolder: 'playwright-report' }],
  ['list'],
];
if (process.env.PLAYWRIGHT_JUNIT_OUTPUT_FILE) {
  reporter.push(['junit']);
}

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  forbidOnly: false,
  retries: 0,
  workers: flutterWorkerBudget(),
  reporter,
  use: {
    baseURL: process.env.FLUTTER_WEB_BASE_URL || 'http://localhost:8080',
    trace: process.env.FLUTTER_WEB_LIGHT === '1' ? 'off' : 'on-first-retry',
    screenshot: 'only-on-failure',
    video: process.env.FLUTTER_WEB_LIGHT === '1' ? 'off' : 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      // Android-oriented browser emulation; not physical-device evidence.
      name: 'mobile-chromium',
      grep: /@portable/,
      use: { ...devices['Pixel 7'] },
    },
    {
      // iPhone/iOS-oriented WebKit emulation; do not label this real Safari proof.
      name: 'mobile-webkit',
      grep: /@portable/,
      use: { ...devices['iPhone 13'] },
    },
  ],
});
