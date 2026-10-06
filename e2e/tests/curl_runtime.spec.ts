import { test, expect, Page, Route, Locator } from '@playwright/test';
import { waitForFlutter } from '../utils/helpers';

const endpoint = '**/__runtime__/curl-import';
const region = (page: Page, id: string) => page.locator(`[flt-semantics-identifier="${id}"]`);
const input = (page: Page) => region(page, 'curl-import-input').getByRole('textbox');
const url = (page: Page) => region(page, 'http-draft-url').getByRole('textbox');
// Verified against retained Flutter DOM traces: state is descendant text.
const state = (page: Page) => region(page, 'curl-runtime-state');
async function submit(page: Page) {
  const action = region(page, 'curl-import-action');
  await expect(action).toHaveCount(1);
  await action.evaluate((node) => {
    const target = node.hasAttribute('flt-tappable') ? node : node.querySelector('[flt-tappable]');
    if (!(target instanceof HTMLElement)) throw new Error('curl import action is not tappable');
    target.click();
  });
}
// Flutter hydrates the active semantics editor from its TextEditingController.
// Unfocused semantics inputs can be empty even when the canvas shows a value.
// Focus and wait for rendering before writing/reading; never seed expected data.
async function activate(field: Locator) {
  await expect(field).toBeEditable();
  await field.focus();
  await expect(field).toBeFocused();
  await field.evaluate(() => new Promise<void>((resolve) => {
    requestAnimationFrame(() => requestAnimationFrame(() => resolve()));
  }));
}
async function editField(field: Locator, text: string) {
  await activate(field);
  await field.fill(text);
  await expect(field).toHaveValue(text);
}
async function edit(page: Page, text: string) {
  await editField(input(page), text);
}
async function expectUrl(page: Page, expected: string) {
  const field = url(page);
  await activate(field);
  await expect(field).toHaveValue(expected);
}

test.use({ trace: 'on', screenshot: 'only-on-failure' });

// Opt-in runtime build only. Ordinary static Pages/portable tests remain separate.
test.describe('Live Python curl import @portable', () => {
  test.skip(process.env.CURL_RUNTIME_E2E !== '1', 'requires explicit Python runtime build/server');
  test.beforeEach(async ({ page }) => {
    await page.goto('http://127.0.0.1:8080/#/tools/http/request-draft');
    await waitForFlutter(page);
    await expect(state(page)).toHaveText('python:ready');
  });

  test('real Python response becomes editor values and produces a snapshot', async ({ page }, testInfo) => {
    // The URL varies per project: this cannot pass by loading a fixed asset.
    const address = `https://example.test/live-${testInfo.project.name}`;
    const raw = `curl -G '${address}' -d 'tag=a&tag=b&blank=&q=%E7%8C%AB'`;
    await edit(page, raw);
    const reply = page.waitForResponse((r) => r.url().endsWith('/__runtime__/curl-import'));
    await submit(page);
    const response = await reply;
    expect(response.status()).toBe(200);
    expect(response.headers()['x-curl-runtime']).toBe('python');
    expect(response.request().postData()).toBe(raw);
    const payload = await response.json();
    expect(payload.result.ok).toBe(true);
    expect(payload.result.draft.query.map((v: {name: string; value: string}) => [v.name, v.value]))
      .toEqual([['tag', 'a'], ['tag', 'b'], ['blank', ''], ['q', '猫']]);
    await expect(state(page)).toHaveText('python:ready');
    await expectUrl(page, address);
    await page.screenshot({ path: testInfo.outputPath('python-curl-import.png'), fullPage: true });
    await testInfo.attach('runtime-receipt', { body: JSON.stringify({
      schema: 'curl-runtime-e2e/1', engine: 'python', project: testInfo.project.name,
      status: response.status(), queryRows: payload.result.draft.query.length,
    }), contentType: 'application/json' });
  });

  test('rejected input retains the existing draft', async ({ page }) => {
    await editField(url(page), 'https://kept.example/');
    await edit(page, 'curl https://example.test -d @not-a-file');
    await submit(page);
    await expect(state(page)).toHaveText(/error\.fileBody/);
    await expectUrl(page, 'https://kept.example/');
  });

  test('unavailable runtime never falls back, and retry can recover', async ({ page }, testInfo) => {
    await editField(url(page), 'https://kept.example/');
    await page.route(endpoint, (route) => route.abort('failed'));
    await edit(page, 'curl https://retry.example/');
    await submit(page);
    await expect(state(page)).toHaveText(/runtimeUnavailable/);
    await expectUrl(page, 'https://kept.example/');
    await page.screenshot({ path: testInfo.outputPath('runtime-unavailable.png'), fullPage: true });
    await page.unroute(endpoint);
    await submit(page);
    await expect(state(page)).toHaveText('python:ready');
    await expectUrl(page, 'https://retry.example/');
  });

  test('timeout is bounded and duplicate submission is blocked', async ({ page }) => {
    let held: Route | undefined;
    let calls = 0;
    await page.route(endpoint, (route) => { held = route; calls++; });
    await edit(page, 'curl https://never-applied.example/');
    await submit(page);
    await expect(state(page)).toHaveText('python:loading');
    await expect(region(page, 'curl-import-action').getByRole('button')).toBeDisabled();
    await expect(state(page)).toHaveText(/runtimeTimeout/, { timeout: 8_000 });
    await expectUrl(page, '');
    expect(calls).toBe(1);
    await held?.abort().catch(() => {});
  });

  test('malformed reply is not treated as successful parsing', async ({ page }) => {
    await page.route(endpoint, (route) => route.fulfill({ status: 200,
      contentType: 'application/json', body: '{"schema":"curl-runtime/1","result":null}' }));
    await edit(page, 'curl https://never-applied.example/');
    await submit(page);
    await expect(state(page)).toHaveText(/runtimeResponse/);
    await expectUrl(page, '');
  });

  test('editing while the real Python reply is delayed invalidates the result', async ({ page }) => {
    let release!: () => void;
    const released = new Promise<void>((resolve) => { release = resolve; });
    await page.route(endpoint, async (route) => {
      const response = await route.fetch();
      await released;
      await route.fulfill({ response });
    });
    await edit(page, 'curl https://late.example/');
    await submit(page);
    await expect(state(page)).toHaveText('python:loading');
    await editField(url(page), 'https://edited.example/');
    release();
    await expect(state(page)).toHaveText('python:ready');
    await expectUrl(page, 'https://edited.example/');
  });
});
