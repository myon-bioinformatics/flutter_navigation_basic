import os from 'node:os';

// Cap browser processes using available CPU and reported memory. This is an
// estimate, not a memory reservation; --workers=1 remains available for diagnosis.
export function workerBudget({ cpus = os.availableParallelism(),
  memory = Math.min(os.totalmem(), process.constrainedMemory?.() || Infinity),
  override = process.env.FLUTTER_WEB_WORKERS } = {}) {
  if (override !== undefined) {
    if (!/^[1-9]\d*$/.test(override) || Number(override) > 32)
      throw new Error('FLUTTER_WEB_WORKERS must be an integer from 1 to 32');
    return Number(override);
  }
  return Math.max(1, Math.min(4, Math.floor(cpus), Math.floor(memory / (2 * 1024 ** 3))));
}
