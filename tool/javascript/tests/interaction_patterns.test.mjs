import test from "node:test";
import assert from "node:assert/strict";
import { debounce, virtualWindow } from "../interaction_patterns.mjs";

test("debounce coalesces events and cancel prevents delivery", () => {
  const callbacks = new Map();
  let id = 0;
  const seen = [];
  const trigger = debounce(value => seen.push(value), 20, {
    setTimeoutFn: fn => { callbacks.set(++id, fn); return id; },
    clearTimeoutFn: key => callbacks.delete(key),
  });
  trigger("first");
  trigger("last");
  assert.equal(callbacks.size, 1);
  const [timerId, callback] = [...callbacks.entries()][0];
  callbacks.delete(timerId);
  callback();
  assert.deepEqual(seen, ["last"]);
  trigger("cancelled");
  trigger.cancel();
  assert.equal(callbacks.size, 0);
});

test("virtual window includes visible rows and clamps boundaries", () => {
  assert.deepEqual(virtualWindow({ count: 100, itemHeight: 20, scrollTop: 200,
    viewportHeight: 100, overscan: 1 }), {
    start: 9, end: 16, topPadding: 180, bottomPadding: 1680,
  });
  assert.deepEqual(virtualWindow({ count: 0, itemHeight: 20, scrollTop: 0,
    viewportHeight: 100 }), { start: 0, end: 0, topPadding: 0, bottomPadding: 0 });
});

test("invalid viewport fails instead of reporting success", () => {
  assert.throws(() => virtualWindow({ count: 10, itemHeight: 0, scrollTop: 0,
    viewportHeight: 100 }), RangeError);
  assert.throws(() => debounce(() => {}, -1), TypeError);
});
