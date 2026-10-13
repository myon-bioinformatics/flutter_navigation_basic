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

// Same snapshot function text as _STORAGE in interaction.py.
const storage = (page) => page.evaluate(() => {
  // Per area: key count and an FNV-1a fingerprint of the sorted key/value pairs,
  // so an overwrite of an existing key is detected without exposing raw values.
  const snap = (name) => {
    try {
      const store = window[name], entries = [];
      for (let i = 0; i < store.length; i++) { const k = store.key(i); entries.push([k, store.getItem(k)]); }
      entries.sort((a, b) => (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0));
      const text = JSON.stringify(entries);
      let h = 0x811c9dc5;
      for (let i = 0; i < text.length; i++) { h ^= text.charCodeAt(i); h = Math.imul(h, 0x01000193); }
      return {keys: entries.length, fingerprint: 'fnv1a32:' + (h >>> 0).toString(16).padStart(8, '0')};
    } catch (e) { return null; }
  };
  return {local: snap('localStorage'), session: snap('sessionStorage')};
});

// Record what a page does while untrusted input is handled: requests, dialogs,
// uncaught errors, popups and Web Storage changes (key count + content
// fingerprint, no raw values). Dialogs are dismissed.
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
        && JSON.stringify(after) === JSON.stringify(before);
      return {schema: 'side-effects/1', quiet, ...seen, storage: {before, after}};
    },
  };
}

export const INVENTORY_SELECTOR = 'flt-semantics, [role], button, a, input, select, textarea';

// List what the page exposes for interaction, before choosing what to press.
// Flutter Web can merge a control into its card (one button-role node ~130px
// tall around a 40px field): pressing that node's centre misses the field.
// Compare boxes here, then press an element with its own boundary/identifier.
// Same function text as _INVENTORY in interaction.py.
export async function inventory(page, {selector = INVENTORY_SELECTOR, limit = 200} = {}) {
  const {total, elements} = await page.evaluate(([selector, limit]) => {
  // Role, aria-label, text, identifier and box of each matching element:
  // shows when a framework merged a control into a larger container.
  const all = document.querySelectorAll(selector), elements = [];
  for (const el of all) {
    if (elements.length >= limit) break;
    const r = el.getBoundingClientRect();
    const text = (el.textContent || '').replace(/\s+/g, ' ').trim();
    elements.push({
      tag: el.tagName.toLowerCase(),
      role: el.getAttribute('role'),
      aria_label: el.getAttribute('aria-label'),
      text: text.length > 120 ? text.slice(0, 119) + '…' : text,
      id: el.getAttribute('flt-semantics-identifier') || el.id || el.getAttribute('data-testid') || null,
      box: {x: Math.round(r.x), y: Math.round(r.y), width: Math.round(r.width), height: Math.round(r.height)},
      in_viewport: r.width > 0 && r.height > 0 && r.bottom > 0 && r.right > 0 && r.top < innerHeight && r.left < innerWidth,
    });
  }
  return {total: all.length, elements};
}, [selector, limit]);
  return {schema: 'element-inventory/1', selector, total, truncated: total > elements.length, elements};
}
