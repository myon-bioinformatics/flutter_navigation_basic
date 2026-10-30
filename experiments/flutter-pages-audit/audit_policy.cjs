'use strict';

// Observer decisions only. These helpers do not activate controls, infer painted
// content, or turn missing browser evidence into a successful observation.
function readinessDecision(snapshot = {}, { attempts = 0, elapsedMs = 0 } = {}) {
  if (!Number.isInteger(attempts) || attempts < 0 || !Number.isFinite(elapsedMs) || elapsedMs < 0) {
    throw new TypeError('Readiness requires nonnegative attempts and finite elapsedMs');
  }
  if (snapshot.titleCount === 1 && snapshot.favoriteCount === 1 && snapshot.titleVisible === true) return 'ready';
  if (elapsedMs >= 25_000) return 'timeout';
  if (snapshot.placeholderCount === 1 && attempts < 3) return 'activate';
  return 'wait';
}

const BUTTON_IDS = ['shared-header-home', 'shared-header-favorite', 'shared-header-menu'];
const FOOTER_MODES = new Set(['fixed', 'scroll-content', 'absent']);
const validBox = box => box && ['x', 'y', 'width', 'height'].every(key => Number.isFinite(box[key])) && box.width > 0 && box.height > 0;

function fullyVisible(box, clip) {
  return !!(validBox(box) && validBox(clip) && clip.x <= box.x + 1 && clip.y <= box.y + 1 &&
    clip.x + clip.width >= box.x + box.width - 1 && clip.y + clip.height >= box.y + box.height - 1);
}

function measuredHeaderMember(item, frame) {
  return item?.headerDescendant === true && fullyVisible(item.box, frame);
}

function chromeProblems(before, after) {
  const problems = [];
  function compare(label, a, b, fixed = true) {
    if (!validBox(a) || !validBox(b)) {
      problems.push(`${label}: missing or invalid measured box`);
      return;
    }
    if (fixed) for (const key of ['x', 'y', 'width', 'height']) {
      if (Math.abs(a[key] - b[key]) > 1) problems.push(`${label}.${key}: changed by more than 1px`);
    }
  }
  compare('headerFrame', before?.headerFrame, after?.headerFrame);
  for (const id of BUTTON_IDS) {
    const a = before?.header?.[id], b = after?.header?.[id];
    if (a?.count !== 1 || b?.count !== 1) problems.push(`${id}: requires exactly one witness before and after`);
    compare(id, a?.box, b?.box);
  }
  const mode = before?.footerMode, nextMode = after?.footerMode;
  if (!FOOTER_MODES.has(mode) || !FOOTER_MODES.has(nextMode)) {
    problems.push('footerMode: missing or unknown structural classification');
  } else if (mode !== nextMode) {
    problems.push('footerMode: structural classification changed');
  } else if (mode === 'absent') {
    if (before.footer !== null || after.footer !== null) problems.push('footer: absent mode requires explicit null witnesses');
  } else {
    // A Door nested in a body scroller is content, not fixed chrome. Allowing its
    // movement is not evidence that the end or the Door itself was reached.
    compare('footer', before.footer, after.footer, mode === 'fixed');
  }
  // The title identifier encloses intrinsic Text/Row glyph metrics, not the
  // AppBar frame. Font-metric changes remain diagnostic, not a scroll oracle.
  return problems;
}

// A gesture can temporarily hide semantic overflow. Wait without further input
// for the original regions to reappear and two consecutive structural samples.
function scrollSettled(previous, current, regionIds) {
  if (!Array.isArray(regionIds) || !regionIds.length || new Set(regionIds).size !== regionIds.length) return false;
  const signature = snapshot => {
    if (!snapshot || !Array.isArray(snapshot.regions)) return null;
    const regions = regionIds.map(id => snapshot.regions.filter(r => r.id === id));
    if (regions.some(matches => matches.length !== 1)) return null;
    const witnesses = regions.map(([r]) => r);
    if (witnesses.some(r => !validBox(r.box) || !['auto', 'scroll'].includes(r.overflowY) ||
        ![r.scrollTop, r.scrollHeight, r.clientHeight].every(Number.isFinite))) return null;
    return JSON.stringify({ regions: witnesses.map(r => ({ id: r.id, box: r.box, overflowY: r.overflowY,
      scrollTop: r.scrollTop, scrollHeight: r.scrollHeight, clientHeight: r.clientHeight })),
      footerMode: snapshot.footerMode, footer: snapshot.footer, footerClip: snapshot.footerClip });
  };
  const a = signature(previous), b = signature(current);
  return a !== null && b !== null && a === b;
}

module.exports = { readinessDecision, chromeProblems, fullyVisible, scrollSettled, measuredHeaderMember };
