import { expect, type Page, type TestInfo } from '@playwright/test';
import { choice } from './explore_plan.mjs';
import { press } from './interaction.mjs';

// Bounded UI exploration, not exhaustive coverage. Never execute arbitrary
// export/delete/upload controls or cross-origin links on the published site.
export async function explore(page: Page, info: TestInfo, route: string, seed: string, steps: number) {
  const actions: unknown[] = [];
  const errors: string[] = [];
  const onError = (error: Error) => errors.push(error.message);
  page.on('pageerror', onError);
  try {
    for (let step = 0; step < steps; step++) {
      const fields = page.locator('input:not([type=file]):not([type=password]):not([type=hidden]), textarea');
      const buttons = page.getByRole('button', { name: /^(追加|挿入|クリア|リセット|検索|次へ|戻る|Add|Insert|Clear|Reset|Search|Next|Back)$/i });
      const candidates: { kind: string; index?: number }[] = [
        { kind: 'tab' }, { kind: 'escape' }, { kind: 'scroll' },
      ];
      for (let i = 0; i < Math.min(await fields.count(), 20); i++) {
        if (await fields.nth(i).isVisible() && await fields.nth(i).isEditable()) candidates.push({ kind: 'fill', index: i });
      }
      for (let i = 0; i < Math.min(await buttons.count(), 20); i++) {
        if (await buttons.nth(i).isVisible() && await buttons.nth(i).isEnabled()) candidates.push({ kind: 'press', index: i });
      }
      const action = candidates[choice(seed, route, step, candidates.length)];
      const record: Record<string, unknown> = { step, ...action, url: page.url() };
      actions.push(record);
      try {
        if (action.kind === 'fill') {
          const values = ['', '0', '-1', '日本語🙂', 'a'.repeat(128)];
          const field = fields.nth(action.index!);
          // Native number/date controls reject arbitrary text before app code.
          const type = await field.getAttribute('type');
          record.value = type === 'number' ? '0' : values[choice(seed, route, `value-${step}`, values.length)];
          if (!type || ['text', 'search', 'email', 'url', 'tel', 'number'].includes(type)) {
            await field.fill(String(record.value), { timeout: 3000 });
          } else record.skipped = `unsupported input type ${type}`;
        } else if (action.kind === 'press') {
          record.label = await buttons.nth(action.index!).getAttribute('aria-label') || await buttons.nth(action.index!).innerText();
          await press(page, buttons.nth(action.index!), { timeout: 3000 });
        } else if (action.kind === 'scroll') {
          await page.mouse.wheel(0, choice(seed, route, `scroll-${step}`, 2) ? 400 : -400);
        } else await page.keyboard.press(action.kind === 'tab' ? 'Tab' : 'Escape');
        await expect(page.locator('flt-glass-pane')).toBeAttached({ timeout: 3000 });
        expect(errors, 'Uncaught JavaScript errors during exploration').toEqual([]);
      } catch (error) {
        record.error = String(error);
        throw error;
      }
    }
  } finally {
    page.off('pageerror', onError);
    await info.attach('exploration.json', { body: Buffer.from(JSON.stringify({
      schema: 'flutter-web-exploration/1', seed, route, steps, actions, errors,
      worker: info.workerIndex, parallel_slot: info.parallelIndex,
    }, null, 2)), contentType: 'application/json' });
  }
}
