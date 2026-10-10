import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { processRequest } from '../future_patterns.mjs';

const make = (mode, extra) => ({ mode, ...extra });
test('121 basic resolves', async () => assert.equal((await processRequest(make('basic', {task:{value:'ok'}}))).value, 'ok'));
test('122 chain applies steps in order', async () => assert.equal((await processRequest(make('chain', {task:{value:2}, steps:[{op:'multiply',by:3},{op:'add',by:1}]}))).value, 7));
test('123 catches rejection with explicit fallback', async () => {
  const value = (await processRequest(make('error',{task:{value:null,reject:'broken'},fallback:'safe'}))).value;
  assert.deepEqual(value, {caught:'broken',fallback:'safe'});
});
test('124 Promise.all retains input order', async () => {
  const value=(await processRequest(make('wait',{tasks:[{value:'slow',delay_ms:25},{value:'fast'}]}))).value;
  assert.deepEqual(value,['slow','fast']);
});
test('125 Promise.race takes first settlement, including rejection', async () => {
  const value=(await processRequest(make('any',{tasks:[{value:'slow',delay_ms:30},{value:'fast'}]}))).value;
  assert.equal(value,'fast');
  await assert.rejects(processRequest(make('any',{tasks:[{value:'late',delay_ms:30},{value:null,reject:'first'}]})), /first/);
});
test('126 timeout fails, and success path resolves', async () => {
  await assert.rejects(processRequest(make('timeout',{task:{value:1,delay_ms:30},timeout_ms:5})), /timeout/);
  assert.equal((await processRequest(make('timeout',{task:{value:1},timeout_ms:100}))).value,1);
});
test('invalid contracts fail closed', async () => {
  for (const req of [
    {mode:'basic',task:{value:1},other:2},
    {mode:'chain',task:{value:1},steps:[{op:'uppercase'}]},
    {mode:'wait',tasks:[]},
    {mode:'any',tasks:[{value:1,delay_ms:-1}]},
    {mode:'timeout',task:{value:1},timeout_ms:0},
    {mode:'error',task:{value:1}},
  ]) await assert.rejects(processRequest(req));
});
test('CLI produces strict stdout JSON and exit 2 on failure', () => {
  const cmd = new URL('../future_patterns.mjs', import.meta.url).pathname;
  const run = input => spawnSync(process.execPath,[cmd],{input:JSON.stringify(input),encoding:'utf8'});
  const good=run({mode:'basic',task:{value:[1,2]}});
  assert.equal(good.status,0);
  assert.deepEqual(JSON.parse(good.stdout),{schema:'future-patterns/1',mode:'basic',value:[1,2]});
  const bad=run({mode:'wait',tasks:[]});
  assert.equal(bad.status,2);assert.equal(bad.stdout,'');assert.match(bad.stderr,/invalid input/);
});
