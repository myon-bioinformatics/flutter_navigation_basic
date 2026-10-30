'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { readinessDecision, chromeProblems, fullyVisible } = require('./audit_policy.cjs');

test('flowing Door reach needs the complete measured clipped box, not raw viewport inclusion', () => {
  const door = { x: 32, y: 400, width: 326, height: 40 };
  assert.equal(fullyVisible(door, { ...door }), true);
  assert.equal(fullyVisible(door, { ...door, height: 12 }), false);
  assert.equal(fullyVisible(door, { ...door, x: 100, width: 258 }), false);
  assert.equal(fullyVisible(door, null), false);
  assert.equal(fullyVisible(door, { ...door, height: NaN }), false);
});

const ready = { titleCount: 1, favoriteCount: 1, titleVisible: true, placeholderCount: 0 };
function chrome(footerMode = 'fixed') {
  return {
    headerFrame: { x: 0, y: 0, width: 390, height: 104 },
    header: Object.fromEntries(['shared-header-home', 'shared-header-favorite', 'shared-header-menu'].map((id, i) => [id, {
      count: 1, box: { x: 270 + i * 40, y: 8, width: 40, height: 40 },
    }])),
    footerMode,
    footer: footerMode === 'absent' ? null : { x: 12, y: 346, width: 366, height: 122 },
  };
}

test('readiness requires the unique title and favorite, not arbitrary semantics', () => {
  assert.equal(readinessDecision(ready), 'ready');
  assert.equal(readinessDecision({ semanticsCount: 100 }), 'wait');
  for (const change of [{ titleCount: 0 }, { titleCount: 2 }, { favoriteCount: 0 }, { favoriteCount: 2 }, { titleVisible: false }, { titleVisible: 'true' }]) {
    assert.equal(readinessDecision({ ...ready, ...change }), 'wait');
  }
});

test('only a unique placeholder can receive at most three activation attempts', () => {
  for (const attempts of [0, 1, 2]) assert.equal(readinessDecision({ placeholderCount: 1 }, { attempts, elapsedMs: 24_999 }), 'activate');
  assert.equal(readinessDecision({ placeholderCount: 1 }, { attempts: 3, elapsedMs: 10 }), 'wait');
  for (const placeholderCount of [0, 2, undefined]) assert.equal(readinessDecision({ placeholderCount }), 'wait');
});

test('the deadline takes priority over activation but not established readiness', () => {
  assert.equal(readinessDecision({ placeholderCount: 1 }, { attempts: 0, elapsedMs: 25_000 }), 'timeout');
  assert.equal(readinessDecision({}, { attempts: 3, elapsedMs: 30_000 }), 'timeout');
  assert.equal(readinessDecision(ready, { attempts: 3, elapsedMs: 30_000 }), 'ready');
});

test('invalid readiness timing or attempt evidence is rejected', () => {
  for (const options of [{ attempts: -1 }, { attempts: .5 }, { elapsedMs: NaN }, { elapsedMs: Infinity }, { elapsedMs: -1 }]) {
    assert.throws(() => readinessDecision({}, options), TypeError);
  }
});

test('unchanged fixed, flow, and explicitly absent chrome pass', () => {
  for (const mode of ['fixed', 'scroll-content', 'absent']) assert.deepEqual(chromeProblems(chrome(mode), chrome(mode)), []);
});

test('fixed footer movement fails; scroll-content footer movement is allowed', () => {
  for (const mode of ['fixed', 'scroll-content']) {
    const after = chrome(mode); after.footer.y -= 844;
    assert.equal(chromeProblems(chrome(mode), after).length === 0, mode === 'scroll-content');
  }
});

test('missing or invalid header frame cannot silently pass', () => {
  for (const value of [undefined, null, { x: 0, y: 0, width: 0, height: 104 }, { x: NaN, y: 0, width: 390, height: 104 }]) {
    const after = chrome(); after.headerFrame = value;
    assert.ok(chromeProblems(chrome(), after).some(problem => problem.startsWith('headerFrame:')));
  }
  assert.ok(chromeProblems(undefined, undefined).length > 0);
});

test('two-pixel drift in any header frame or shared button dimension is rejected', () => {
  for (const id of [null, 'shared-header-home', 'shared-header-favorite', 'shared-header-menu']) {
    for (const key of ['x', 'y', 'width', 'height']) {
      const after = chrome(); const box = id ? after.header[id].box : after.headerFrame;
      box[key] += 2;
      assert.ok(chromeProblems(chrome(), after).length > 0, `${id || 'headerFrame'}.${key}`);
    }
  }
});

test('one-pixel tolerance is bounded inclusively', () => {
  const after = chrome(); after.headerFrame.y += 1; after.header['shared-header-home'].box.x -= 1;
  assert.deepEqual(chromeProblems(chrome(), after), []);
  after.headerFrame.y += .01;
  assert.ok(chromeProblems(chrome(), after).length > 0);
});

test('title-only glyph metric change does not impersonate fixed chrome movement', () => {
  const before = chrome(), after = chrome();
  before.header['shared-header-title'] = { count: 1, box: { x: 48, y: 13, width: 214, height: 30 } };
  after.header['shared-header-title'] = { count: 1, box: { x: 48, y: 14, width: 212, height: 28 } };
  assert.deepEqual(chromeProblems(before, after), []);
});

test('missing or duplicate shared controls fail even with other good geometry', () => {
  const after = chrome(); delete after.header['shared-header-favorite'];
  assert.ok(chromeProblems(chrome(), after).some(problem => problem.startsWith('shared-header-favorite:')));
  const duplicate = chrome(); duplicate.header['shared-header-home'].count = 2;
  assert.ok(chromeProblems(chrome(), duplicate).some(problem => problem.startsWith('shared-header-home:')));
});

test('unknown or changing footer classification fails closed', () => {
  for (const footerMode of [undefined, 'unknown', 'none']) {
    const after = chrome(); after.footerMode = footerMode;
    assert.ok(chromeProblems(chrome(), after).some(problem => problem.startsWith('footerMode:')));
  }
  assert.ok(chromeProblems(chrome('fixed'), chrome('scroll-content')).length > 0);
});

test('fixed and flow modes need measured footer boxes; absence needs explicit null', () => {
  for (const mode of ['fixed', 'scroll-content', 'absent']) {
    const after = chrome(mode); delete after.footer;
    assert.ok(chromeProblems(chrome(mode), after).length > 0);
  }
  const after = chrome('scroll-content'); after.footer.height = Infinity;
  assert.ok(chromeProblems(chrome('scroll-content'), after).length > 0);
});

const { scrollSettled } = require('./audit_policy.cjs');
function scrollSample() {
  return { ...chrome('scroll-content'), regions: [{ id: 'scroller', box: { x: 0, y: 104, width: 390, height: 350 },
    overflowY: 'auto', scrollTop: 100, scrollHeight: 450, clientHeight: 350 }] };
}
test('scroll settling needs consecutive original-region witnesses, never just elapsed time', () => {
  assert.equal(scrollSettled(scrollSample(), scrollSample(), ['scroller']), true);
  for (const ids of [[], ['other'], ['scroller', 'scroller']]) assert.equal(scrollSettled(scrollSample(), scrollSample(), ids), false);
  assert.equal(scrollSettled(null, scrollSample(), ['scroller']), false);
  for (const value of ['hidden', 'clip', 'visible', undefined]) {
    const current = scrollSample(); current.regions[0].overflowY = value;
    assert.equal(scrollSettled(scrollSample(), current, ['scroller']), false);
  }
});
test('missing, duplicate, moving and invalid region samples cannot settle', () => {
  const changes = [s => s.regions.pop(), s => s.regions.push(s.regions[0]),
    s => s.regions[0].scrollTop++, s => s.regions[0].box.y++,
    s => s.regions[0].clientHeight = NaN, s => s.footerMode = 'fixed', s => s.footer.y++];
  for (const change of changes) {
    const current = scrollSample(); change(current);
    assert.equal(scrollSettled(scrollSample(), current, ['scroller']), false);
  }
});

const { measuredHeaderMember } = require('./audit_policy.cjs');
test('Hub search exemption requires measured containment AND actual header ancestry', () => {
  const frame = { x: 0, y: 0, width: 390, height: 160 };
  const hubSearch = { headerDescendant: true, box: { x: 16, y: 112, width: 358, height: 40 } };
  assert.equal(measuredHeaderMember(hubSearch, frame), true);
  assert.equal(measuredHeaderMember({ ...hubSearch, headerDescendant: false }, frame), false);
  assert.equal(measuredHeaderMember({ ...hubSearch, headerDescendant: 'true' }, frame), false);
  assert.equal(measuredHeaderMember(hubSearch, null), false);
  assert.equal(measuredHeaderMember({ ...hubSearch, box: { ...hubSearch.box, y: 367 } }, frame), false);
  assert.equal(measuredHeaderMember({ ...hubSearch, box: { ...hubSearch.box, height: 0 } }, frame), false);
});
