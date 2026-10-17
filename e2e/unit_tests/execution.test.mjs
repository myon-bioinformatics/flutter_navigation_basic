import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import { workerBudget } from '../utils/worker_budget.mjs';
import { choice } from '../utils/explore_plan.mjs';

test('small/container runners stay bounded; explicit diagnostics can serialize', () => {
  const gib = 1024 ** 3;
  assert.equal(workerBudget({ cpus: 1, memory: gib, override: undefined }), 1);
  assert.equal(workerBudget({ cpus: 8, memory: 4 * gib, override: undefined }), 2);
  assert.equal(workerBudget({ cpus: 64, memory: 128 * gib, override: undefined }), 4);
  assert.equal(workerBudget({ cpus: 8, memory: 16 * gib, override: '1' }), 1);
  for (const override of ['0', '-1', 'Infinity', '2.5', '33', ''])
    assert.throws(() => workerBudget({ override }));
});

test('seed/route choices replay across scheduling orders and vary across seeds', () => {
  const plan = (seed, route) => Array.from({ length: 30 }, (_, i) => choice(seed, route, i, 11));
  const a = plan('run-1', '/screen1');
  plan('run-2', '/screen2');
  assert.deepEqual(plan('run-1', '/screen1'), a);
  assert.notDeepEqual(plan('run-2', '/screen1'), a);
  assert.notDeepEqual(plan('run-1', '/screen2'), a);
  assert.throws(() => choice('seed', '/', 0, 0));
});

test('actual Playwright workers overlap, replace a failed worker, and finish remaining tests', () => {
  const dir = mkdtempSync(path.join(tmpdir(), 'flutter-worker-check-'));
  const require = createRequire(import.meta.url);
  const entry = require.resolve('@playwright/test');
  const cli = path.join(path.dirname(entry), 'cli.js');
  const events = path.join(dir, 'events.jsonl');
  try {
    writeFileSync(path.join(dir, 'playwright.config.cjs'), `module.exports = {
      testDir: ${JSON.stringify(dir)}, fullyParallel: false, workers: 2, retries: 0,
      reporter: [['junit', {outputFile: ${JSON.stringify(path.join(dir, 'junit.xml'))}}]],
      outputDir: ${JSON.stringify(path.join(dir, 'results'))},
    };`);
    const header = `const {test,expect}=require(${JSON.stringify(entry)});
      const fs=require('node:fs');
      function event(kind, info) { fs.appendFileSync(${JSON.stringify(events)}, JSON.stringify({
        kind, title:info.title, worker:info.workerIndex, at:Date.now()})+'\\n'); }
      test.beforeEach(async({},info)=>event('start',info));
      test.afterEach(async({},info)=>event('end',info));`;
    writeFileSync(path.join(dir, 'a.spec.cjs'), header + `
      test('intentional failure',async()=>{await new Promise(r=>setTimeout(r,500));expect(1).toBe(2)});
      test('after replacement',async()=>{});`);
    writeFileSync(path.join(dir, 'b.spec.cjs'), header + `
      test('concurrent work',async()=>{await new Promise(r=>setTimeout(r,1200))});
      test('remaining work',async()=>{});`);
    const result = spawnSync(process.execPath, [cli, 'test', '-c', path.join(dir, 'playwright.config.cjs')],
      { encoding: 'utf8', timeout: 30_000, env: { ...process.env, PLAYWRIGHT_HTML_OPEN: 'never' } });
    assert.equal(result.status, 1, result.stderr);
    const rows = readFileSync(events, 'utf8').trim().split('\n').map(JSON.parse);
    const start = title => rows.find(row => row.title === title && row.kind === 'start');
    const end = title => rows.find(row => row.title === title && row.kind === 'end');
    assert.notEqual(start('intentional failure').worker, start('after replacement').worker);
    assert.ok(end('remaining work'));
    assert.ok(Math.max(start('intentional failure').at, start('concurrent work').at)
      < Math.min(end('intentional failure').at, end('concurrent work').at));
    let active = 0, peak = 0;
    for (const row of rows) { active += row.kind === 'start' ? 1 : -1; peak = Math.max(peak, active); }
    assert.equal(peak, 2);
    assert.equal(active, 0);
    const xml = readFileSync(path.join(dir, 'junit.xml'), 'utf8');
    assert.match(xml, /tests="4"/);
    assert.match(xml, /failures="1"/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
