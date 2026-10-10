// Node.js 22+ Promise reference implementation for catalogue 121-126.
// This models portable Promise semantics, not Dart Future runtime identity.
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const modes = new Set(['basic', 'chain', 'error', 'wait', 'any', 'timeout']);
function object(value, name) {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new TypeError(name + ' must be an object');
  }
  return value;
}
function keys(obj, allowed, required = []) {
  for (const key of Object.keys(obj)) if (!allowed.includes(key)) throw new TypeError('unknown field ' + key);
  for (const key of required) if (!Object.hasOwn(obj, key)) throw new TypeError('missing field ' + key);
}
function task(input) {
  const t = object(input, 'task');
  keys(t, ['value', 'delay_ms', 'reject'], ['value']);
  const delay = t.delay_ms ?? 0;
  if (!Number.isInteger(delay) || delay < 0 || delay > 1000) throw new TypeError('delay_ms must be an integer 0..1000');
  if (t.reject !== undefined && (typeof t.reject !== 'string' || !t.reject)) throw new TypeError('reject must be a nonempty string');
  return new Promise((resolve, reject) => setTimeout(
    () => t.reject === undefined ? resolve(t.value) : reject(new Error(t.reject)), delay));
}
export async function processRequest(input) {
  const req = object(input, 'request');
  keys(req, ['mode', 'task', 'tasks', 'steps', 'timeout_ms', 'fallback'], ['mode']);
  const mode = req.mode;
  if (!modes.has(mode)) throw new TypeError('unsupported mode');
  let value;
  if (mode === 'wait' || mode === 'any') {
    keys(req, ['mode', 'tasks'], ['tasks']);
    if (!Array.isArray(req.tasks) || !req.tasks.length || req.tasks.length > 32) throw new TypeError('tasks must contain 1..32 tasks');
    const jobs = req.tasks.map(task);
    value = mode === 'wait' ? await Promise.all(jobs) : await Promise.race(jobs);
  } else {
    const allowed = mode === 'chain' ? ['mode','task','steps'] :
      mode === 'error' ? ['mode','task','fallback'] :
      mode === 'timeout' ? ['mode','task','timeout_ms'] : ['mode','task'];
    keys(req, allowed, ['task']);
    let job = task(req.task);
    if (mode === 'chain') {
      if (!Array.isArray(req.steps) || !req.steps.length || req.steps.length > 32) throw new TypeError('steps must contain 1..32 steps');
      for (const step of req.steps) {
        object(step, 'step');
        keys(step, ['op', 'by'], ['op']);
        if (step.op === 'add' || step.op === 'multiply') {
          if (typeof step.by !== 'number' || !Number.isFinite(step.by)) throw new TypeError('numeric by required');
          const op = step.op;
          job = job.then(x => {
            if (typeof x !== 'number' || !Number.isFinite(x)) throw new TypeError('numeric input required');
            return op === 'add' ? x + step.by : x * step.by;
          });
        } else if (step.op === 'uppercase') {
          keys(step, ['op']);
          job = job.then(x => {
            if (typeof x !== 'string') throw new TypeError('string input required');
            return x.toUpperCase();
          });
        } else throw new TypeError('unsupported step');
      }
    }
    if (mode === 'error') {
      if (!Object.hasOwn(req, 'fallback')) throw new TypeError('fallback required');
      job = job.catch(error => ({ caught: error.message, fallback: req.fallback }));
    }
    if (mode === 'timeout') {
      if (!Number.isInteger(req.timeout_ms) || req.timeout_ms < 1 || req.timeout_ms > 1000) throw new TypeError('timeout_ms must be 1..1000');
      // Timer is disposed even when the task wins. This is a Promise.race equivalent,
      // not cancellation of the underlying task.
      let timer;
      const timeout = new Promise((_, reject) => {
        timer = setTimeout(() => reject(new Error('timeout')), req.timeout_ms);
      });
      try { value = await Promise.race([job, timeout]); }
      finally { clearTimeout(timer); }
    } else value = await job;
  }
  return { schema: 'future-patterns/1', mode, value };
}
async function main() {
  try {
    const index = process.argv.indexOf('--input');
    if (index >= 0 && (index !== 2 || !process.argv[3] || process.argv.length !== 4)) throw new TypeError('usage: --input path');
    if (index < 0 && process.argv.length !== 2) throw new TypeError('usage: --input path');
    const text = index < 0 ? readFileSync(0, 'utf8') : readFileSync(process.argv[3], 'utf8');
    const result = await processRequest(JSON.parse(text));
    process.stdout.write(JSON.stringify(result) + '\n');
  } catch (error) {
    process.stderr.write('invalid input: ' + String(error.message) + '\n');
    process.exitCode = 2;
  }
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) await main();
