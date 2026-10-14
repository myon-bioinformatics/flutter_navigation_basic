/** Browser-neutral pure event scheduling and virtual viewport contracts. */
export function debounce(callback, delayMs, { setTimeoutFn = setTimeout, clearTimeoutFn = clearTimeout } = {}) {
  if (typeof callback !== "function" || !Number.isFinite(delayMs) || delayMs < 0) {
    throw new TypeError("invalid debounce arguments");
  }
  let timer;
  const invoke = (...args) => {
    if (timer !== undefined) clearTimeoutFn(timer);
    timer = setTimeoutFn(() => { timer = undefined; callback(...args); }, delayMs);
  };
  invoke.cancel = () => {
    if (timer !== undefined) clearTimeoutFn(timer);
    timer = undefined;
  };
  return invoke;
}

export function virtualWindow({ count, itemHeight, scrollTop, viewportHeight, overscan = 2 }) {
  for (const value of [count, itemHeight, scrollTop, viewportHeight, overscan]) {
    if (!Number.isFinite(value) || value < 0) throw new RangeError("invalid viewport number");
  }
  if (!Number.isInteger(count) || !Number.isInteger(overscan) || itemHeight === 0) {
    throw new RangeError("invalid viewport configuration");
  }
  const start = Math.max(0, Math.min(count, Math.floor(scrollTop / itemHeight) - overscan));
  const end = Math.max(start, Math.min(count, Math.ceil((scrollTop + viewportHeight) / itemHeight) + overscan));
  return { start, end, topPadding: start * itemHeight, bottomPadding: (count - end) * itemHeight };
}
