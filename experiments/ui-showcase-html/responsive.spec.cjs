'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const { pathToFileURL } = require('node:url');
const fromE2E = createRequire(path.join(__dirname, '../../e2e/package.json'));
const { test, expect } = fromE2E('@playwright/test');
const interaction = import(pathToFileURL(path.join(__dirname, '../../e2e/utils/interaction.mjs')).href);
const cases = [
  { width: 899, height: 757 }, { width: 900, height: 757 },
  { width: 1179, height: 757 }, { width: 1180, height: 757 },
  { width: 320, height: 500 }, { width: 390, height: 320 },
  { width: 900, height: 240 },
];
const byId = (page, id) => page.getByTestId(id);
const settle = async page => {
  await page.waitForTimeout(150);
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
};

async function scrollState(page) {
  return page.evaluate(() => {
    const main = document.querySelector('[data-testid="showcase-overview-scroll"]');
    const root = document.scrollingElement;
    return { main: main.scrollTop, document: root.scrollTop,
      mainRange: Math.max(0, main.scrollHeight - main.clientHeight),
      documentRange: Math.max(0, root.scrollHeight - root.clientHeight) };
  });
}

async function layout(page) {
  return page.evaluate(() => {
    const rect = el => {
      if (!el || getComputedStyle(el).display === 'none') return null;
      const r = el.getBoundingClientRect();
      return { x: r.x, y: r.y, width: r.width, height: r.height, right: r.right, bottom: r.bottom };
    };
    const main = document.querySelector('[data-testid="showcase-overview-scroll"]');
    const mainBox = main.getBoundingClientRect(), style = getComputedStyle(main);
    const contentLeft = mainBox.left + main.clientLeft + parseFloat(style.paddingLeft);
    const contentRight = mainBox.left + main.clientLeft + main.clientWidth - parseFloat(style.paddingRight);
    const ids = ['shared-header-primary', 'shared-header-title', 'shared-header-favorite',
      'showcase-body-layout', 'showcase-overview-scroll', 'showcase-rail', 'shared-footer',
      'showcase-bottom-navigation', 'prototype-diagnostics'];
    return {
      viewport: { width: innerWidth, height: innerHeight, dpr: devicePixelRatio },
      boxes: Object.fromEntries(ids.map(id => [id, rect(document.querySelector(`[data-testid="${id}"]`))])),
      horizontal: { root: document.documentElement.scrollWidth - document.documentElement.clientWidth,
        main: main.scrollWidth - main.clientWidth },
      mainOverflowY: style.overflowY,
      headerControls: [...document.querySelectorAll('.header-primary button')].map(rect),
      chips: [...document.querySelectorAll('.ui-tag')].map(el => ({ text: el.textContent, box: rect(el),
        leftCutoff: Math.max(0, contentLeft - el.getBoundingClientRect().left),
        rightCutoff: Math.max(0, el.getBoundingClientRect().right - contentRight),
        ownOverflow: el.scrollWidth - el.clientWidth })),
      textOverflow: [...document.querySelectorAll('.overview-heading, .info-card h3, .info-card p')]
        .map(el => ({ text: el.textContent, overflow: el.scrollWidth - el.clientWidth })),
      navigation: [...document.querySelectorAll('.bottom-item .nav-icon')].map(rect),
      footerField: rect(document.querySelector('.tool-field')),
    };
  });
}

async function favoriteHit(page) {
  return byId(page, 'shared-header-favorite').evaluate(el => {
    const r = el.getBoundingClientRect(), x = Math.floor(r.x + r.width / 2), y = Math.floor(r.y + r.height / 2);
    const top = document.elementFromPoint(x, y);
    return { x, y, fullyInViewport: r.left >= 0 && r.top >= 0 && r.right <= innerWidth && r.bottom <= innerHeight,
      ownsHit: !!top && (top === el || el.contains(top)) };
  });
}

async function finalTextWitness(page) {
  return page.locator('.info-card:last-child p').evaluate(el => {
    const text = el.lastChild, range = document.createRange();
    range.setStart(text, Math.max(0, text.textContent.length - 1));
    range.setEnd(text, text.textContent.length);
    const r = range.getBoundingClientRect();
    const main = el.closest('main'), box = main.getBoundingClientRect();
    const clips = getComputedStyle(main).overflowY !== 'visible';
    const top = Math.max(0, clips ? box.top : 0), bottom = Math.min(innerHeight, clips ? box.bottom : innerHeight);
    return { box: { x: r.x, y: r.y, right: r.right, bottom: r.bottom, height: r.height },
      visible: r.width > 0 && r.height > 0 && r.left >= 0 && r.right <= innerWidth + 1 && r.top >= top - 1 && r.bottom <= bottom + 1 };
  });
}

for (const viewport of cases) {
  const compact = viewport.width < 900;
  const fallback = viewport.height <= (compact ? 458 : 378);
  test(`native ${viewport.width}x${viewport.height}: ${fallback ? 'document-scroll fallback' : 'body-scroll layout'} remains reachable`, async ({ page }, info) => {
    const record = { schema: 'ui-showcase-native-responsive/1', viewport, fallback, flutterParityAsserted: false,
      candidateSha: process.env.CANDIDATE_SHA || null, inputs: [], status: 'incomplete' };
    const capture = async name => {
      const file = info.outputPath(`${name}.png`);
      await page.screenshot({ path: file });
      await info.attach(name, { path: file, contentType: 'image/png' });
    };
    try {
      await page.setViewportSize(viewport);
      await page.goto('/');
      const favorite = byId(page, 'shared-header-favorite');
      const main = byId(page, 'showcase-overview-scroll');
      await expect(favorite).toBeEnabled();
      await settle(page);
      record.initial = await layout(page);
      await capture('initial');
      expect(record.initial.viewport).toEqual({ ...viewport, dpr: 1 });
      expect.soft(record.initial.horizontal.root, 'no horizontal document overflow').toBeLessThanOrEqual(1);
      expect.soft(record.initial.horizontal.main, 'no clipped horizontal Overview overflow').toBeLessThanOrEqual(1);
      expect(record.initial.boxes['showcase-body-layout'].height, 'Overview must have a usable nonzero track').toBeGreaterThanOrEqual(120);
      expect(record.initial.mainOverflowY).toBe(fallback ? 'visible' : 'auto');
      expect(record.initial.boxes['showcase-rail'] === null).toBe(compact);
      expect(record.initial.boxes['showcase-bottom-navigation'] === null).toBe(!compact);
      const boxes = record.initial.boxes;
      expect.soft(boxes['shared-header-primary'].bottom).toBeLessThanOrEqual(boxes['showcase-body-layout'].y + 1);
      expect.soft(boxes['showcase-body-layout'].bottom).toBeLessThanOrEqual(boxes['shared-footer'].y + 1);
      expect.soft(record.initial.footerField.bottom, 'footer field stays inside the footer').toBeLessThanOrEqual(boxes['shared-footer'].bottom + 1);
      if (!compact) expect.soft(boxes['showcase-rail'].right).toBeLessThanOrEqual(boxes['showcase-overview-scroll'].x + 1);
      for (const control of record.initial.headerControls) {
        expect.soft(control.x).toBeGreaterThanOrEqual(0);
        expect.soft(control.right).toBeLessThanOrEqual(viewport.width + 1);
        expect.soft(control.width).toBeGreaterThanOrEqual(39);
        expect.soft(control.height).toBeGreaterThanOrEqual(39);
      }
      for (let index = 1; index < record.initial.headerControls.length; index++) {
        expect.soft(record.initial.headerControls[index - 1].right, 'header controls must not overlap').toBeLessThanOrEqual(record.initial.headerControls[index].x + 1);
      }
      expect.soft(boxes['shared-header-title'].right, 'title must not overlap Home').toBeLessThanOrEqual(record.initial.headerControls[1].x + 1);
      for (const chip of record.initial.chips) {
        expect.soft(Math.max(chip.leftCutoff, chip.rightCutoff, chip.ownOverflow), `chip text must not be clipped: ${chip.text}`).toBeLessThanOrEqual(1);
      }
      for (const item of record.initial.textOverflow) expect.soft(item.overflow, `body text must not be clipped: ${item.text}`).toBeLessThanOrEqual(1);
      if (compact) for (let index = 1; index < record.initial.navigation.length; index++) {
        expect.soft(record.initial.navigation[index - 1].right, 'compact navigation icons must not overlap').toBeLessThanOrEqual(record.initial.navigation[index].x + 1);
      }
      record.initialHit = await favoriteHit(page);
      expect(record.initialHit).toMatchObject({ fullyInViewport: true, ownsHit: true });
      const { press } = await interaction;
      for (const selected of [true, false]) {
        record.inputs.push(await press(page, favorite, { touch: false }));
        await expect(favorite).toHaveAttribute('aria-pressed', String(selected));
      }
      let tabs = 0;
      for (; tabs < 12;) {
        await page.keyboard.press('Tab'); tabs++;
        await settle(page);
        if (await favorite.evaluate(el => document.activeElement === el)) break;
      }
      record.inputs.push({ input: 'keyboard', key: 'Tab', presses: tabs });
      await expect(favorite).toBeFocused();
      await page.keyboard.press('Space');
      await expect(favorite).toHaveAttribute('aria-pressed', 'true');
      await page.keyboard.press('Enter');
      await expect(favorite).toHaveAttribute('aria-pressed', 'false');
      record.inputs.push({ input: 'keyboard', keys: ['Space', 'Enter', 'Tab'] });
      await page.keyboard.press('Tab');
      await expect(main).toBeFocused();

      const owner = fallback ? 'document' : 'main';
      const home = fallback ? 'Control+Home' : 'Home';
      await page.keyboard.press(home);
      await expect.poll(async () => (await scrollState(page))[owner]).toBeLessThanOrEqual(1);
      record.beforeScroll = await scrollState(page);
      const box = await main.boundingBox();
      const x = Math.floor(box.x + 12), y = Math.floor((Math.max(0, box.y) + Math.min(viewport.height, box.y + box.height)) / 2);
      await page.mouse.move(x, y);
      await page.mouse.wheel(0, 200);
      await settle(page);
      record.afterWheel = await scrollState(page);
      record.inputs.push({ input: 'mouse-wheel', x, y, deltaY: 200 });
      if (record.beforeScroll[`${owner}Range`] > 1) expect(record.afterWheel[owner], 'real wheel must move the current scroll owner').toBeGreaterThan(record.beforeScroll[owner]);
      expect(fallback ? record.afterWheel.main : record.afterWheel.document, 'there is only one active vertical scroll owner').toBeLessThanOrEqual(1);

      await page.keyboard.press(home);
      await expect.poll(async () => (await scrollState(page))[owner]).toBeLessThanOrEqual(1);
      await page.keyboard.press('PageDown');
      await settle(page);
      record.afterPageDown = await scrollState(page);
      record.inputs.push({ input: 'keyboard', keys: [home, 'PageDown'] });
      if (record.beforeScroll[`${owner}Range`] > 1) expect(record.afterPageDown[owner], 'PageDown must move the current scroll owner').toBeGreaterThan(1);
      await expect(main).toBeFocused();
      await page.keyboard.press(fallback ? 'Control+End' : 'End');
      await settle(page);
      record.inputs.push({ input: 'keyboard', key: fallback ? 'Control+End' : 'End' });
      record.finalText = await finalTextWitness(page);
      expect(record.finalText.visible, 'the last text character must be geometrically reachable, not merely DOM-visible').toBe(true);
      record.footerAtEnd = await byId(page, 'shared-footer').boundingBox();
      expect(record.footerAtEnd.y, 'footer is reachable at the end').toBeGreaterThanOrEqual(-1);
      expect(record.footerAtEnd.y + record.footerAtEnd.height, 'footer is not clipped below the viewport at the end').toBeLessThanOrEqual(viewport.height + 1);
      record.atEnd = await scrollState(page);
      await capture('end-content');

      await page.keyboard.press('Shift+Tab');
      await expect(favorite).toBeFocused();
      await settle(page);
      record.returnHit = await favoriteHit(page);
      expect(record.returnHit, 'keyboard return must expose a real operable favorite hit target').toMatchObject({ fullyInViewport: true, ownsHit: true });
      await page.keyboard.press('Space');
      await expect(favorite).toHaveAttribute('aria-pressed', 'true');
      record.inputs.push({ input: 'keyboard', keys: ['Shift+Tab', 'Space'] });
      await capture('return-to-favorite');
      record.status = info.errors.length ? 'failed' : 'complete';
    } catch (error) {
      record.status = 'failed'; record.failure = String(error); throw error;
    } finally {
      try { await capture('final'); } catch (error) { record.captureError = String(error); }
      record.errors = info.errors.map(error => error.message);
      console.log('UI_SHOWCASE_RESPONSIVE ' + JSON.stringify(record));
      const file = info.outputPath('responsive.json');
      fs.mkdirSync(path.dirname(file), { recursive: true });
      fs.writeFileSync(file, JSON.stringify(record, null, 2) + '\n');
      await info.attach('responsive', { path: file, contentType: 'application/json' });
    }
  });
}
