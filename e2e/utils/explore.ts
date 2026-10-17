/** Flutter policy/attachments only. Generic execution is maintained upstream. */
import { expect, type Page, type TestInfo } from '@playwright/test';
import { writeFile } from 'node:fs/promises';
import { explore as explorePage } from './browser_execution.mjs';

export async function explore(page: Page, info: TestInfo, route: string, seed: string, steps: number) {
  let receipt: unknown;
  let failure: unknown;
  try {
    receipt = await explorePage(page, {
      route, seed, steps,
      buttonName: /^(追加|挿入|クリア|リセット|検索|次へ|戻る|Add|Insert|Clear|Reset|Search|Next|Back)$/i,
      values: ['', '0', '-1', '日本語🙂', 'a'.repeat(128)],
      ready: async () => expect(page.locator('flt-glass-pane')).toBeAttached({ timeout: 3000 }),
    });
  } catch (error) {
    failure = error;
    receipt = (error as { receipt?: unknown }).receipt;
    throw error;
  } finally {
    try {
      const output = info.outputPath('exploration.json');
      await writeFile(output, JSON.stringify({ ...receipt as object,
        schema: 'flutter-web-exploration/1', worker: info.workerIndex, parallel_slot: info.parallelIndex,
      }, null, 2));
      await info.attach('exploration.json', { path: output, contentType: 'application/json' });
    } catch (error) {
      if (!failure) throw error;
      console.warn('Exploration evidence capture failed:', String(error));
    }
  }
}
