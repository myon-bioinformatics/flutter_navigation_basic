import test from 'node:test';
import assert from 'node:assert/strict';
import { revealByKeyboard, tapKeyboardRevealed } from '../../e2e/utils/flutter_keyboard_reveal.mjs';

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
