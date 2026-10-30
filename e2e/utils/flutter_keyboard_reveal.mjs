import { pressPoint } from './interaction.mjs';

// Flutter-local accessibility adapter. Keyboard traversal can ask Flutter to
// reveal its focused widget; DOM scrollIntoView only moves the semantics tree.
// This is keyboard-assisted reachability, NOT a touch-swipe implementation.
const ownsFocus = target => target.evaluate(el =>
  el.matches(':focus') || el.contains(document.activeElement));

async function frames(page) {
  await page.evaluate(() => new Promise(resolve => {
    requestAnimationFrame(() => requestAnimationFrame(() => resolve()));
  }));
}

function sameBox(a, b) {
  return !!a && !!b && ['x', 'y', 'width', 'height'].every(key =>
    Number.isFinite(a[key]) && Number.isFinite(b[key]) && Math.abs(a[key] - b[key]) < 0.5);
}

function visiblePoint(box, viewport, minimumHeight) {
  if (!viewport) throw Error('Keyboard reveal needs an explicit viewport');
  if (!box || box.height < minimumHeight || box.y < 104 ||
      box.y + box.height > viewport.height - 24) {
    throw Error('Keyboard target is clipped or overlaps fixed page chrome');
  }
  return pressPoint(box, viewport, 1);
}

export async function revealByKeyboard(page, target, { minimumHeight = 40, maxTabs = 64 } = {}) {
  if (!Number.isInteger(maxTabs) || maxTabs < 1 || maxTabs > 64) throw Error('Invalid Tab budget');
  if (await target.count() !== 1) throw Error('Keyboard target must be unique');
  const inputs = [];
  for (let index = 0; index < maxTabs && !await ownsFocus(target); index++) {
    await page.keyboard.press('Tab');
    await frames(page);
    inputs.push({ input: 'keyboard', key: 'Tab' });
  }
  // An in-viewport DOM box is not sufficient: stale overlay geometry can look
  // exactly like a valid field while the canvas still shows another control.
  if (!await ownsFocus(target)) throw Error('Keyboard traversal did not focus the target');
  const before = await target.boundingBox();
  await frames(page);
  const after = await target.boundingBox();
  if (!sameBox(before, after)) throw Error('Keyboard target geometry did not settle');
  visiblePoint(after, page.viewportSize(), minimumHeight);
  return { schema: 'flutter-keyboard-reveal/1', input: 'keyboard', inputs,
    reason: 'mobile-webkit-wheel-unsupported', minimum_height: minimumHeight,
    box: after, canvas_alignment: 'requires-browser-pixel-verification' };
}

// Only for a previously keyboard-revealed control. Never silently scroll it
// again between the caller's screenshot and the real touch input.
export async function tapKeyboardRevealed(page, target, reveal) {
  if (reveal?.schema !== 'flutter-keyboard-reveal/1') throw Error('Missing keyboard reveal');
  if (await target.count() !== 1 || !await ownsFocus(target)) throw Error('Keyboard target lost focus');
  const box = await target.boundingBox();
  if (!sameBox(reveal.box, box)) throw Error('Keyboard target moved after reveal');
  const { x, y, visible_ratio } = visiblePoint(box, page.viewportSize(), reveal.minimum_height);
  const hit = await target.evaluate((el, [x, y]) => {
    const top = document.elementFromPoint(x, y);
    return { tag: top ? top.tagName.toLowerCase() : null,
      self: !!top && (top === el || el.contains(top)) };
  }, [x, y]);
  // Diagnostic only: Flutter's canvas input layer can be the top element even
  // for a correctly painted control (the successful clean Door receipt has
  // hit.self=false). Do not invent a DOM-occlusion guarantee from this value.
  // Focus/full stable geometry remain required; actual painted-field identity
  // and menu outcome must be verified in the built-browser evidence.
  await page.touchscreen.tap(x, y);
  return { schema: 'pointer-press/1', input: 'touch', input_source: 'explicit',
    x, y, visible_ratio, box, hit, reveal: 'keyboard', scroll_after_reveal: false };
}

// Pure provenance validation: workflow merge SHA and built candidate are distinct.
export function verifiedCandidate(candidateSha, provenance) {
  if (!/^[0-9a-f]{40}$/.test(candidateSha ?? '') ||
      !provenance || provenance.candidateSha !== candidateSha ||
      !/^[0-9a-f]{64}$/.test(provenance.builtBundleSha256 ?? '')) {
    throw Error('Missing or mismatched candidate build provenance');
  }
  return { candidate_sha: candidateSha, built_bundle_sha256: provenance.builtBundleSha256 };
}
