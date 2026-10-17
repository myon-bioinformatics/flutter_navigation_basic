import os from 'node:os';
import { createHash } from 'node:crypto';
import { press } from './interaction.mjs';

// Cap browser processes using available CPU and reported memory. This is an
// estimate, not a memory reservation; --workers=1 remains available for diagnosis.
export function workerBudget({ cpus = os.availableParallelism(),
  memory = Math.min(os.totalmem(), process.constrainedMemory?.() || Infinity),
  override } = {}) {
  if (override !== undefined) {
    if (!/^[1-9]\d*$/.test(override) || Number(override) > 32)
      throw new Error('worker override must be an integer from 1 to 32');
    return Number(override);
  }
  return Math.max(1, Math.min(4, Math.floor(cpus), Math.floor(memory / (2 * 1024 ** 3))));
}


// Stateless choices are independent of worker scheduling, test ordering/retries.
export function choice(seed, route, step, count) {
  if (!Number.isInteger(count) || count < 1) throw new Error('No exploration choices');
  return createHash('sha256').update(JSON.stringify([seed, route, step])).digest().readUInt32BE(0) % count;
}


export class ExplorationError extends Error {
  constructor(cause, receipt) {
    super(String(cause?.message || cause), { cause });
    this.name = 'ExplorationError';
    this.receipt = receipt;
  }
}

// One existing page, not a route walker. Use route_trail.py for emoji identities
// and ordered navigation. Applications supply readiness, button/input policies
// and any xprobe-derived input corpus; no browser is installed or launched here.
export async function explore(page, { route, seed, steps,
  fieldsSelector = 'input:not([type=file]):not([type=password]):not([type=hidden]), textarea',
  buttonName = null, values = [''], ready = async () => {} } = {}) {
  if (!Number.isInteger(steps) || steps < 0 || steps > 20 ||
      typeof seed !== 'string' || !seed || typeof route !== 'string' || !route ||
      !Array.isArray(values) || !values.length || values.some(v => typeof v !== 'string'))
    throw new TypeError('Expected seed, route, steps 0..20 and nonempty string values');
  const actions = [];
  const errors = [];
  const onError = (error) => { if (errors.length < 100) errors.push(error.message.slice(0, 1000)); };
  page.on('pageerror', onError);
  try {
    for (let step = 0; step < steps; step++) {
      const fields = page.locator(fieldsSelector);
      const buttons = buttonName ? page.getByRole('button', { name: buttonName }) : null;
      const candidates = [
        { kind: 'tab' }, { kind: 'escape' }, { kind: 'scroll' },
      ];
      for (let i = 0; i < Math.min(await fields.count(), 20); i++) {
        if (await fields.nth(i).isVisible() && await fields.nth(i).isEditable()) candidates.push({ kind: 'fill', index: i });
      }
      for (let i = 0; i < Math.min(buttons ? await buttons.count() : 0, 20); i++) {
        if (await buttons.nth(i).isVisible() && await buttons.nth(i).isEnabled()) candidates.push({ kind: 'press', index: i });
      }
      const action = candidates[choice(seed, route, step, candidates.length)];
      const record = { step, ...action, url: page.url() };
      actions.push(record);
      try {
        if (action.kind === 'fill') {
          const field = fields.nth(action.index);
          // Native number/date controls reject arbitrary text before app code.
          record.label = await field.getAttribute('aria-label') || await field.getAttribute('placeholder');
          const type = await field.getAttribute('type');
          record.value = type === 'number' ? '0' : values[choice(seed, route, `value-${step}`, values.length)];
          if (!type || ['text', 'search', 'email', 'url', 'tel', 'number'].includes(type)) {
            await field.fill(String(record.value), { timeout: 3000 });
          } else record.skipped = `unsupported input type ${type}`;
        } else if (action.kind === 'press') {
          record.label = await buttons.nth(action.index).getAttribute('aria-label') || await buttons.nth(action.index).innerText();
          await press(page, buttons.nth(action.index), { timeout: 3000 });
        } else if (action.kind === 'scroll') {
          await page.mouse.wheel(0, choice(seed, route, `scroll-${step}`, 2) ? 400 : -400);
        } else await page.keyboard.press(action.kind === 'tab' ? 'Tab' : 'Escape');
        await ready(page);
        record.after_url = page.url();
        if (errors.length) throw new Error('Uncaught JavaScript errors: ' + errors.join('; '));
      } catch (error) {
        record.error = String(error);
        throw error;
      }
    }
  } catch (error) {
    throw new ExplorationError(error, { schema: 'browser-exploration/1', ok: false,
      seed, route, steps, actions, errors });
  } finally {
    page.off('pageerror', onError);
  }
  return { schema: 'browser-exploration/1', ok: true, seed, route, steps, actions, errors };
}
