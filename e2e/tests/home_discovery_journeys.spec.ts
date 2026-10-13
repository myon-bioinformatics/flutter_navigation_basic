import { test, expect, type Locator, type Page, type TestInfo } from '@playwright/test';
import { createHash } from 'node:crypto';
import { writeFileSync } from 'node:fs';
import { waitForFlutter } from '../utils/helpers';
import { press as kitPress } from '../utils/interaction.mjs';

// Flutter's route/menu transitions (300–450ms in the pinned SDK) are painted
// into the canvas, not CSS animations. Semantics/URL can update before painting.
async function settleCanvas(page: Page) {
  await page.waitForTimeout(600);
  await page.evaluate(() => new Promise<void>((resolve) => {
    requestAnimationFrame(() => requestAnimationFrame(() => requestAnimationFrame(() => resolve())));
  }));
}

// Flutter paints the controls: send measured, in-viewport mouse/touch input at
// the integer centre (browser-test-kit interaction.press), not a DOM click.
async function press(page: Page, target: Locator, testInfo: TestInfo) {
  await expect(target).toHaveCount(1);
  await expect(target).toBeVisible();
  await settleCanvas(page);
  return kitPress(page, target, { touch: !!testInfo.project.use.hasTouch });
}

// Exercise the rendered return leg, including the shared unsaved-work dialog.
// A page.goto('/') would only prove that a fresh Home page can load.
async function returnHome(page: Page, testInfo: TestInfo) {
  const home = page.locator('[flt-semantics-identifier="shared-header-home"]').getByRole('button');
  const records = [await press(page, home, testInfo)];
  const dialog = page.getByRole('alertdialog');
  await expect(dialog).toBeVisible();
  records.push(await press(page, dialog.getByRole('button', { name: 'Home', exact: true }), testInfo));
  await expect(dialog).toHaveCount(0);
  await expect(page).toHaveURL(/#\/?$|\/$/);
  await expect(page.locator('[flt-semantics-identifier="shared-header-title"]')).toContainText('🏠');
  return records;
}

const escape = (text: string) => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// A Home card is an InkWell: Flutter merges its title and subtitle into one
// semantics node, so an exact text match never sees the title alone (same as
// the merged menu text in shared_header.spec.ts). Match the title as a prefix
// and require exactly one card.
async function homeCard(page: Page, title: string) {
  const card = page.getByText(new RegExp(`^${escape(title)}`));
  await expect(card).toHaveCount(1);
  return card;
}

// Door destinations are exposed as menu items by name.
async function doorItem(page: Page, name: string | RegExp) {
  const item = typeof name === 'string'
    ? page.getByRole('menuitem', { name, exact: true })
    : page.getByRole('menuitem', { name });
  await expect(item).toHaveCount(1);
  return item;
}

// The Card previously merged the button role with its title and hint (122–130px
// tall), so even getByRole('button') measured the Card centre. The explicit field
// semantics boundary now identifies just the actual DropdownButtonFormField.
async function doorButton(page: Page, current: string) {
  const button = page.locator('[flt-semantics-identifier="tool-door-dropdown"]');
  await expect(button).toHaveCount(1);
  await expect(button).toBeVisible();
  // URL Params also includes its screen number/icon before "(current)".
  await expect(button).toContainText(new RegExp(`${escape(current)}.*current`));
  return button;
}

// DOM scrollIntoView can move Flutter's semantics overlay without moving the
// painted canvas (observed in the Chromium failure PNG). Drive the actual
// scrollable body with wheel input before the kit measures/taps the field.
async function scrollDoorIntoCanvas(page: Page, field: Locator, scrolls: unknown[], testInfo: TestInfo) {
  if (testInfo.project.name === 'mobile-webkit') {
    // Playwright explicitly rejects wheel input in mobile WebKit. Its semantics
    // scrolling already completed the route in prior runs; keep the real touch
    // press, with viewport/frame checks, rather than skipping or DOM-clicking.
    const before = await field.boundingBox();
    await field.scrollIntoViewIfNeeded();
    await page.evaluate(() => new Promise<void>((resolve) => {
      requestAnimationFrame(() => requestAnimationFrame(() => requestAnimationFrame(() => resolve())));
    }));
    const after = await field.boundingBox();
    scrolls.push({ input: 'semantics-scroll', reason: 'mobile-webkit-wheel-unsupported', before, after });
    await expect(field).toBeInViewport({ ratio: 0.9 });
    return;
  }
  const view = page.viewportSize()!;
  const x = Math.floor(view.width / 2);
  const y = Math.floor(view.height / 2);
  const delta = Math.floor(view.height * 0.8);
  await page.mouse.move(x, y);
  for (let index = 0; index < 16; index++) {
    const before = await field.boundingBox();
    await page.mouse.wheel(0, delta);
    // Observe browser frames; do not synthesize a DOM scroll/click or retry a
    // missed tap. Two stable samples after real input mean the body has settled.
    await page.evaluate(() => new Promise<void>((resolve) => {
      requestAnimationFrame(() => requestAnimationFrame(() => requestAnimationFrame(() => resolve())));
    }));
    const after = await field.boundingBox();
    scrolls.push({ input: 'wheel', x, y, delta_y: delta, before, after });
    if (index > 0 && before && after && after.y >= 104 &&
        after.y + after.height <= view.height &&
        Math.abs(before.y - after.y) < 0.5) {
      await expect(field).toBeInViewport({ ratio: 0.9 });
      return;
    }
  }
  throw new Error('Door field did not settle in the viewport after real wheel input');
}

// Record the measured input and require the menu to actually open before
// looking for a destination. Do not retry the same non-interactive card centre.
async function openDoor(page: Page, field: Locator, testInfo: TestInfo, attempts: unknown[]) {
  const items = page.locator('[role="menuitem"]');
  const record = await press(page, field, testInfo);
  const attempt = { via: 'button-press', opened: false, record };
  attempts.push(attempt);
  await expect(items.first()).toBeVisible({ timeout: 3_000 });
  attempt.opened = true;
}

test.describe('Home discovery journeys', () => {
  test.setTimeout(90_000);
  test.use({ actionTimeout: 10_000 });
  test.afterEach(async ({ page }, testInfo) => {
    if (testInfo.status === testInfo.expectedStatus) return;
    const first = (testInfo.error?.message ?? '').split('\n').find((line) => line.trim()) ?? '';
    console.log(`::notice title=journey ${testInfo.project.name}::${testInfo.title} :: ${first.slice(0, 300)}`);
    const snapshot = await page.locator('flt-semantics').evaluateAll((elements) => elements.map((el) => {
      const box = el.getBoundingClientRect();
      return { role: el.getAttribute('role'), id: el.getAttribute('flt-semantics-identifier'),
        name: el.getAttribute('aria-label'), text: el.textContent?.slice(0, 180),
        box: { x: box.x, y: box.y, width: box.width, height: box.height } };
    }).filter((el) => el.role || el.id || (el.text && el.text.length < 180))).catch(() => []);
    await testInfo.attach('flutter-semantics.json', {
      body: JSON.stringify(snapshot, null, 2), contentType: 'application/json',
    });
    // Keep the relevant DOM observations in logs as well as the artifact.
    console.log(`journey-semantics ${testInfo.project.name} ${JSON.stringify(snapshot.filter((el) =>
      /door|current|Photo Studio|Screen\d+|shared-header/i.test(`${el.id} ${el.name} ${el.text}`)))}`);
  });

  test('visits three distinct Home tools and returns each time @portable', async ({ page }, testInfo) => {
    const targets = [
      { label: 'Navigation Hub', route: /#\/hub$/ },
      { label: 'UI Showcase', route: /#\/examples\/ui-showcase$/ },
      { label: 'MCP Integration', route: /#\/examples\/external-integration\/mcp$/ },
    ];
    for (const [index, target] of targets.entries()) {
      await page.goto('/');
      await waitForFlutter(page);
      await press(page, await homeCard(page, target.label), testInfo);
      await waitForFlutter(page);
      await expect(page).toHaveURL(target.route);
      const path = testInfo.outputPath(`home-journey-${index + 1}.png`);
      await page.screenshot({ path });
      await testInfo.attach(`home-journey-${index + 1}`, { path, contentType: 'image/png' });
      await returnHome(page, testInfo);
    }
  });

  test('Door-to-Door dropdown navigates from URL Params to another tool @portable', async ({ page }, testInfo) => {
    await page.goto('/#/screen5');
    await waitForFlutter(page);
    await expect(page).toHaveURL(/#\/screen5$/);
    const field = await doorButton(page, 'URL Params');
    await scrollDoorIntoCanvas(page, field, [], testInfo);
    await openDoor(page, field, testInfo, []);
    await press(page, await doorItem(page, 'Photo Studio'), testInfo);
    await waitForFlutter(page);
    await expect(page).toHaveURL(/#\/tools\/media\/photo-studio$/);
    const path = testInfo.outputPath('door-to-door-photo-studio.png');
    await page.screenshot({ path });
    await testInfo.attach('door-to-door-photo-studio', { path, contentType: 'image/png' });
    await returnHome(page, testInfo);
  });

  test('Home draw → stable tool Door → drawn screen with screenshot evidence @portable', async ({ page }, testInfo) => {
    // Match every numbered card, including 109/119/.../189, then validate IDs.
    const cardPattern = /^Screen\d+ · /;
    const captures: Array<{
      stage: string; route: string; header: string; header_source: string;
      file: string; bytes: number; sha256: string;
    }> = [];
    const title = page.locator('[flt-semantics-identifier="shared-header-title"]');
    const pixelGuards: Record<string, { clip: { x: number; y: number; width: number; height: number }; file: string; sha256: string }> = {};

    async function headerPixels(stage: string, reference?: string, different = false) {
      const box = reference ? pixelGuards[reference].clip : await title.boundingBox();
      expect(box).not.toBeNull();
      const clip = { x: Math.floor(box!.x), y: Math.floor(box!.y),
        width: Math.floor(box!.width), height: Math.floor(box!.height) };
      let png: Buffer;
      await expect.poll(async () => {
        png = await page.screenshot({ clip, animations: 'disabled' });
        const hash = createHash('sha256').update(png).digest('hex');
        return !reference || (different ? hash !== pixelGuards[reference].sha256 : hash === pixelGuards[reference].sha256);
      }, { timeout: 5_000, message: `Canvas header pixels must identify ${stage}` }).toBe(true);
      const file = `${stage}-header.png`;
      const path = testInfo.outputPath(file);
      writeFileSync(path, png!);
      pixelGuards[stage] = { clip, file, sha256: createHash('sha256').update(png!).digest('hex') };
      await testInfo.attach(file, { path, contentType: 'image/png' });
    }

    async function capture(stage: string, file: string, sourceHeader?: string) {
      await settleCanvas(page);
      // An open Flutter dropdown may hide the underlying page's semantics.
      // For that one capture, retain the title measured before opening it.
      const header = sourceHeader ?? await title.innerText();
      if (stage === 'home-draw' || stage === 'source-tool') await headerPixels(stage);
      if (stage === 'discovered-screen') await headerPixels(stage, 'source-tool', true);
      if (stage === 'returned-home') await headerPixels(stage, 'home-draw');
      const path = testInfo.outputPath(file);
      const png = await page.screenshot({ path, animations: 'disabled' });
      expect(png.subarray(0, 8).toString('hex')).toBe('89504e470d0a1a0a');
      expect(png.length).toBeGreaterThan(1000);
      captures.push({
        stage, route: new URL(page.url()).hash,
        header, header_source: sourceHeader === undefined ? 'current-page' : 'source-tool-before-menu',
        file, bytes: png.length,
        sha256: createHash('sha256').update(png).digest('hex'),
      });
      await testInfo.attach(file, { path, contentType: 'image/png' });
    }

    let ids: number[] = [];
    let labels: string[] = [];
    let complete = false;
    let step = 'open-home';
    const doorAttempts: unknown[] = [];
    const doorScrolls: unknown[] = [];
    let returnPresses: unknown[] = [];
    try {
      await page.goto('/');
      await waitForFlutter(page);
      const cards = page.getByText(cardPattern);
      await expect(cards).toHaveCount(3);
      labels = await cards.allTextContents();
      ids = labels.map((label) => Number(label.match(/^Screen(\d+) · /)?.[1]));
      expect(ids.every((id) => Number.isInteger(id) && id >= 6 && id <= 198)).toBeTruthy();
      expect(new Set(ids).size).toBe(3);

      await cards.first().scrollIntoViewIfNeeded();
      await expect(cards.first()).toBeInViewport();
      await capture('home-draw', 'home-draw.png');
      step = 'press-home-photo-studio';
      await press(page, await homeCard(page, 'Photo Studio'), testInfo);
      await waitForFlutter(page);
      await expect(page).toHaveURL(/#\/tools\/media\/photo-studio$/);
      step = 'scroll-source-door';
      const field = await doorButton(page, 'Photo Studio');
      await scrollDoorIntoCanvas(page, field, doorScrolls, testInfo);
      await capture('source-tool', 'source-tool.png');
      const sourceHeader = await title.innerText();

      step = 'open-door';
      await openDoor(page, field, testInfo, doorAttempts);
      // The Door label is homeDiscoveryLabel(); the card text also carries its subtitle.
      step = 'find-door-item';
      const destination = await doorItem(page, new RegExp(`^Screen${ids[0]} · `));
      await destination.scrollIntoViewIfNeeded();
      await expect(destination).toBeInViewport();
      await capture('door-menu', 'door-menu.png', sourceHeader);
      step = 'press-door-item';
      await press(page, destination, testInfo);
      await waitForFlutter(page);
      await expect(page).toHaveURL((url) => url.hash === `#/screen${ids[0]}`);
      await capture('discovered-screen', 'discovered-screen.png');

      step = 'return-home';
      returnPresses = await returnHome(page, testInfo);
      await capture('returned-home', 'returned-home.png');
      complete = true;
    } finally {
      // Written on success and failure; only the return leg completing sets
      // stage "complete". A failed receipt names the last completed capture.
      const receipt = {
        schema: 'flutter-door-route-audit/1',
        stage: complete ? 'complete' : 'failed',
        last_capture: captures.at(-1)?.stage ?? null,
        failed_step: complete ? null : step,
        door_attempts: doorAttempts,
        door_scrolls: doorScrolls,
        return_presses: returnPresses,
        // Door entries Flutter exposed at the time (names only), to tell a
        // closed menu from an item that is not built/named as expected.
        menu_items: complete ? null : await page.locator('[role="menuitem"]').evaluateAll(
          (els) => els.map((el) => el.getAttribute('aria-label') ?? el.textContent ?? '').slice(0, 40),
        ).catch(() => null),
        project: testInfo.project.name,
        source: 'Home discovery → rendered Door-to-Door',
        ids, labels,
        viewport: page.viewportSize(),
        expected_sha: process.env.EXPECTED_SHA ?? null,
        ci_sha: process.env.GITHUB_SHA ?? null,
        run_id: process.env.GITHUB_RUN_ID ?? null,
        run_attempt: process.env.GITHUB_RUN_ATTEMPT ?? null,
        captures,
        pixel_guards: pixelGuards,
      };
      const manifest = testInfo.outputPath('route-audit.json');
      writeFileSync(manifest, JSON.stringify(receipt, null, 2));
      await testInfo.attach('route-audit.json', { path: manifest, contentType: 'application/json' });
      // Job logs and artifacts may be unreadable to reviewing agents; annotations are not.
      console.log(`::notice title=route-audit ${testInfo.project.name}::stage=${receipt.stage} last=${receipt.last_capture} failed_step=${receipt.failed_step} ids=${ids.join(',')} route=${new URL(page.url()).hash} menu=${JSON.stringify(receipt.menu_items)?.slice(0, 300)} door=${JSON.stringify(doorAttempts).slice(0, 700)}`);
    }
  });
});
