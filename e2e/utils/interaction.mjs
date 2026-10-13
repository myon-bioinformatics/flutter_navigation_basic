// Measured input and side-effect observation for an existing Playwright Page.
// No runtime dependency on import: the caller owns Page, Locator and Playwright.
// Python twin: scripts/interaction.py (same records, same rules).

const round = (v) => Math.round(v * 1000) / 1000;

// Integer pixels: engines round fractional hit/click coordinates differently
// (docs/antipatterns.md FRACTIONAL_HIT_COORDINATES).
export function pressPoint(box, viewport, ratio = 0.9) {
  if (!(ratio > 0 && ratio <= 1)) throw Error('ratio must be in (0, 1]');
  if (!box || !(box.width >= 1 && box.height >= 1)) throw Error('press target has no layout box');
  const w = Math.max(0, Math.min(box.x + box.width, viewport.width) - Math.max(box.x, 0));
  const h = Math.max(0, Math.min(box.y + box.height, viewport.height) - Math.max(box.y, 0));
  const visible = (w * h) / (box.width * box.height);
  if (visible < ratio) throw Error(`press target is ${visible.toFixed(2)} in the viewport; need ${ratio}`);
  return {x: Math.floor(box.x + box.width / 2), y: Math.floor(box.y + box.height / 2), visible_ratio: round(visible)};
}

// Real pointer/touch input at the measured centre of a visible target.
// Use it where the DOM node is not the hit target: Flutter Web (canvas + semantics
// overlay), canvas UIs, or overlays that forward input by coordinates.
// locator.click() then fails as "intercepts pointer events" and el.click() bypasses
// the real hit path (SYNTHETIC_DOM_CLICK).
export async function press(page, target, {touch, ratio = 0.9, timeout = 10000} = {}) {
  await target.scrollIntoViewIfNeeded({timeout});
  await target.waitFor({state: 'visible', timeout});
  const viewport = page.viewportSize() ?? await page.evaluate(() => ({width: innerWidth, height: innerHeight}));
  const box = await target.boundingBox();
  const {x, y, visible_ratio} = pressPoint(box, viewport, ratio);
  // Observation only: under a canvas UI the top element is expected not to be the target.
  const hit = await target.evaluate((el, [x, y]) => {
    const top = document.elementFromPoint(x, y);
    return {tag: top ? top.tagName.toLowerCase() : null, self: !!top && (top === el || el.contains(top))};
  }, [x, y]);
  const source = touch === undefined ? 'navigator.maxTouchPoints' : 'explicit';
  if (touch === undefined) touch = await page.evaluate(() => navigator.maxTouchPoints > 0);
  if (touch) await page.touchscreen.tap(x, y);
  else await page.mouse.click(x, y);
  return {schema: 'pointer-press/1', input: touch ? 'touch' : 'mouse', input_source: source, x, y,
    visible_ratio, box: {x: round(box.x), y: round(box.y), width: round(box.width), height: round(box.height)}, hit};
}

const storage = (page) => page.evaluate(() => {
  const size = (name) => { try { return window[name].length; } catch { return null; } };
  return {local: size('localStorage'), session: size('sessionStorage')};
});

// Record what a page does while untrusted input is handled: requests, dialogs,
// uncaught errors, popups and Web Storage size. Dialogs are dismissed.
// Assert late: keep the record as JSON and check it at the end (or with
// `python -S scripts/interaction.py check record.json`).
export async function watch(page, {dismissDialogs = true} = {}) {
  const seen = {requests: [], dialogs: [], page_errors: [], popups: []};
  const handlers = {
    request: (r) => seen.requests.push(r.url()),
    dialog: async (d) => { seen.dialogs.push({type: d.type(), message: d.message()}); if (dismissDialogs) await d.dismiss().catch(() => {}); },
    pageerror: (e) => seen.page_errors.push(String(e?.message ?? e)),
    popup: (p) => seen.popups.push(p.url()),
  };
  const before = await storage(page);
  for (const [name, fn] of Object.entries(handlers)) page.on(name, fn);
  return {
    async stop() {
      for (const [name, fn] of Object.entries(handlers)) page.off(name, fn);
      const after = await storage(page);
      const quiet = Object.values(seen).every((list) => list.length === 0)
        && after.local === before.local && after.session === before.session;
      return {schema: 'side-effects/1', quiet, ...seen, storage: {before, after}};
    },
  };
}
