import { readFileSync } from 'node:fs';
import test from 'node:test';
import assert from 'node:assert/strict';
import { revealByKeyboard, tapKeyboardRevealed, verifiedCandidate } from '../../e2e/utils/flutter_keyboard_reveal.mjs';

function harness({ focusAfter = 2, box = { x: 44, y: 512, width: 302, height: 40 } } = {}) {
  const state = { tabs: 0, taps: [], box, focused: focusAfter === 0, count: 1, hitSelf: false };
  const active = {};
  const element = { tagName: 'FLT-SEMANTICS', matches: () => state.focused,
    contains: node => state.focused && node === active };
  const target = {
    count: async () => state.count,
    boundingBox: async () => state.box && { ...state.box },
    evaluate: async (fn, arg) => {
      const previous = globalThis.document;
      globalThis.document = { activeElement: active,
        elementFromPoint: () => state.hitSelf ? element : ({ tagName: 'FLT-SEMANTICS' }) };
      try { return fn(element, arg); } finally { globalThis.document = previous; }
    },
    scrollIntoViewIfNeeded() { throw Error('Forbidden DOM scroll'); },
    focus() { throw Error('Forbidden programmatic focus'); },
  };
  const page = {
    keyboard: { press: async key => {
      assert.equal(key, 'Tab');
      state.tabs++;
      state.focused = state.tabs >= focusAfter;
    } },
    evaluate: async () => {}, // Frame scheduling only; no browser in these unit contracts.
    viewportSize: () => ({ width: 390, height: 664 }),
    touchscreen: { tap: async (x, y) => state.taps.push({ x, y }) },
    mouse: { click() { throw Error('Forbidden mouse fallback'); } },
  };
  return { page, target, state };
}

test('keyboard reveal precedes one measured touch, without a hidden DOM scroll', async () => {
  const { page, target, state } = harness();
  const reveal = await revealByKeyboard(page, target);
  assert.equal(reveal.inputs.length, 2);
  assert.equal(state.taps.length, 0);
  const press = await tapKeyboardRevealed(page, target, reveal);
  assert.deepEqual(state.taps, [{ x: 195, y: 532 }]);
  assert.equal(press.scroll_after_reveal, false);
  assert.equal(reveal.canvas_alignment, 'requires-browser-pixel-verification');
});

test('visible stale semantics box without keyboard focus cannot authorize a tap', async () => {
  const { page, target, state } = harness({ focusAfter: Infinity });
  await assert.rejects(revealByKeyboard(page, target, { maxTabs: 3 }), /did not focus/);
  assert.equal(state.tabs, 3);
  assert.deepEqual(state.taps, []);
});

for (const [name, box] of Object.entries({
  missing: null,
  clipped: { x: 44, y: 512, width: 302, height: 6 },
  header: { x: 44, y: 70, width: 302, height: 40 },
  footer: { x: 44, y: 620, width: 302, height: 40 },
  horizontal: { x: -1, y: 512, width: 302, height: 40 },
})) {
  test(`${name} geometry is rejected before touching`, async () => {
    const { page, target, state } = harness({ focusAfter: 0, box });
    await assert.rejects(revealByKeyboard(page, target));
    assert.deepEqual(state.taps, []);
  });
}

test('geometry drifting across frames does not count as ready', async () => {
  const { page, target, state } = harness({ focusAfter: 0 });
  page.evaluate = async () => { state.box.y += 2; };
  await assert.rejects(revealByKeyboard(page, target), /did not settle/);
  assert.deepEqual(state.taps, []);
});

test('movement after capture/reveal prevents touching another control', async () => {
  const { page, target, state } = harness({ focusAfter: 0 });
  const reveal = await revealByKeyboard(page, target);
  state.box.y += 2;
  await assert.rejects(tapKeyboardRevealed(page, target, reveal), /moved after reveal/);
  assert.deepEqual(state.taps, []);
});

test('lost focus after capture/reveal prevents activation', async () => {
  const { page, target, state } = harness({ focusAfter: 0 });
  const reveal = await revealByKeyboard(page, target);
  state.focused = false;
  await assert.rejects(tapKeyboardRevealed(page, target, reveal), /lost focus/);
  assert.deepEqual(state.taps, []);
});

test('canvas top node outside semantics remains diagnostic, with focus and geometry still required', async () => {
  const { page, target, state } = harness({ focusAfter: 0 });
  const reveal = await revealByKeyboard(page, target);
  state.hitSelf = false;
  const record = await tapKeyboardRevealed(page, target, reveal);
  assert.equal(record.hit.self, false);
  assert.deepEqual(state.taps, [{ x: 195, y: 532 }]);
  state.focused = false;
  await assert.rejects(tapKeyboardRevealed(page, target, reveal), /lost focus/);
  assert.equal(state.taps.length, 1);
});

test('ambiguous targets and fabricated missing receipts are rejected', async () => {
  const { page, target, state } = harness({ focusAfter: 0 });
  state.count = 2;
  await assert.rejects(revealByKeyboard(page, target), /unique/);
  await assert.rejects(tapKeyboardRevealed(page, target, null), /Missing keyboard reveal/);
  assert.deepEqual(state.taps, []);
});

test('candidate receipts require matching immutable checkout and bundle digest', () => {
  const sha = 'a'.repeat(40), digest = 'b'.repeat(64);
  const provenance = { candidateSha: sha, builtBundleSha256: digest };
  assert.deepEqual(verifiedCandidate(sha, provenance), { candidate_sha: sha, built_bundle_sha256: digest });
  for (const [candidate, record] of [[undefined, provenance], [sha, null],
    ['c'.repeat(40), provenance], [sha, { ...provenance, builtBundleSha256: null }],
    ['unknown', provenance], [sha, { ...provenance, candidateSha: undefined }]]) {
    assert.throws(() => verifiedCandidate(candidate, record), /candidate build provenance/);
  }
});

// Exercise the actual browser predicate, not a duplicate implementation. This
// lives in the Node lane; Python wiring checks do not acquire a Node dependency.
test('Generic grid predicate rejects the captured clipped cell and malformed geometry', () => {
  const spec = readFileSync(new URL('../../e2e/focused/generic_responsive.spec.ts', import.meta.url), 'utf8');
  const source = ('function completeGridCell(' + spec.split('function completeGridCell(')[1].split('function completeControl(')[0])
    .replace('box: { width: number; height: number }, bodyWidth: number', 'box, bodyWidth');
  const completeGridCell = new Function(source + '; return completeGridCell;')();
  assert.equal(completeGridCell({width:173,height:99},390),false);
  assert.equal(completeGridCell({width:173,height:173},390),true);
  assert.equal(completeGridCell({width:181.328125,height:181.328125},1180),true);
  for (const [box,width] of [
    [{width:99,height:173},390], [{width:172,height:99},390],
    [{width:173,height:173},1180], [{width:173,height:173},32],
    [{width:173,height:173},NaN], [{width:NaN,height:173},390],
    [{width:173,height:NaN},390], [{width:Infinity,height:173},390],
    [null,390], [{width:0,height:0},390],
  ]) assert.equal(completeGridCell(box,width),false);
});

test('intrinsic reference rejects tiny clickable slivers without inventing text heights', () => {
  const spec = readFileSync(new URL('../../e2e/focused/generic_responsive.spec.ts', import.meta.url), 'utf8');
  const source = ('function completeGridCell(' + spec.split('function completeGridCell(')[1].split('function controlKind(')[0])
    .replace('box: { width: number; height: number }, bodyWidth: number', 'box, bodyWidth')
    .replace('g: any, kind: string, bodyWidth: number, reference: any = null', 'g, kind, bodyWidth, reference = null')
    .replace(' as Record<string, number>', '');
  const completeControl = new Function(source + '; return completeControl;')();
  const g = (width, height) => ({visible:true,box:{x:16,y:200,width,height},clip:{left:0,right:500,top:104,bottom:500}});
  for (const [width,height,full,kind] of [
    [141.328,11,32,'button'], [192.531,11,32,'button'],
    [130,37,48,'tab'], [354.988,5.294,50.824,'interior'],
    [390,79,88,'interior'], [358,99,104,'interior'],
  ]) {
    assert.equal(completeControl(g(width,height),kind,390,{width,height:full}),false);
    assert.equal(completeControl(g(width,full),kind,390,{width,height:full}),true);
  }
  // Editable DOM line and legitimate edge alignment have their OWN reference.
  const input = g(366,54); input.box.y=446;
  assert.equal(completeControl(input,'interior',390,{width:366,height:54}),true);
  assert.equal(completeControl(g(130,80),'navigation',390,{width:130,height:80}),true);
  assert.equal(completeControl(g(173,99),'grid',390,{width:173,height:173}),false);
  assert.equal(completeControl(g(100,20),'interior',390,{width:101,height:NaN}),false);
  assert.equal(completeControl(g(100,20),'interior',390,{width:103,height:20}),false);
  assert.equal(completeControl({...g(100,20),visible:false},'interior',390,{width:100,height:20}),false);
  assert.equal(completeControl(g(0,20),'interior',390,{width:0,height:20}),false);
  for (const clip of [{left:0,right:NaN,top:104,bottom:500}, {left:100,right:0,top:104,bottom:500},
    {left:0,right:500,top:300,bottom:200}, {left:0,right:80,top:104,bottom:500}]) {
    assert.equal(completeControl({...g(100,20),clip},'interior',390,{width:100,height:20}),false);
  }
  assert.equal(completeControl(g(100,20),'interior',NaN,{width:100,height:20}),false);
  assert.match(spec, /for \(const height of \[1600, 1720\]\)/);
  assert.match(spec, /width: original.width, height/);
  assert.match(spec, /expect\(signature\)\.toEqual\(references\[index\]\.signature\)/);
  assert.match(spec, /await page.setViewportSize\(original\)/);
});
