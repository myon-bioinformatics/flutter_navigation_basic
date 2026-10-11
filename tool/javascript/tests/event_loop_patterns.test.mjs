import test from 'node:test';
import assert from 'node:assert/strict';
import {processRequest} from '../event_loop_patterns.mjs';
import {processRequest as stream} from '../stream_patterns.mjs';
test('144/145 share the existing debounce/throttle producer',async()=>{
 const rows=[{at_ms:0,value:'a'},{at_ms:5,value:'b'},{at_ms:20,value:'c'}];
 assert.deepEqual((await stream({mode:'debounce',events:rows,duration_ms:6})).events,[rows[1],rows[2]]);
 assert.deepEqual((await stream({mode:'throttle',events:rows,duration_ms:6})).events,[rows[0],rows[2]]);
});
test('146 reactive map and equality filter',async()=>{
 const x=await processRequest({mode:'reactive',values:[1,2,3],steps:[{op:'map_add',value:1},{op:'where_equals',value:3}]});
 assert.deepEqual(x.result,[3]);
});
test('147 event loop explicit phases',async()=>{
 const x=await processRequest({mode:'event_loop',values:['x']});
 assert.deepEqual(x.result.map(t=>t.phase),['sync','microtask','timer']);
});
test('148 microtask order vs timer',async()=>{
 const x=await processRequest({mode:'microtask',values:[]});
 assert.deepEqual(x.result,['sync','microtask','promise','timer']);
});
test('149 pause/resume reference preserves order',async()=>{
 const x=await processRequest({mode:'suspend_resume',values:[1,2,3],pause_after:1});
 assert.deepEqual(x.result,{values:[1,2,3],trace:['paused','resumed']});
});
test('150 async generator yields values in order',async()=>{
 const x=await processRequest({mode:'async_generator',values:[1,'b',null]});
 assert.deepEqual(x.result,[1,'b',null]);
});
test('invalid requests fail closed',async()=>{
 for(const req of [
  {mode:'reactive',values:[1],steps:[]},
  {mode:'reactive',values:[1],steps:[{op:'map_add',value:'bad'}]},
  {mode:'suspend_resume',values:[1],pause_after:2},
  {mode:'microtask',values:[],extra:1},
 ])await assert.rejects(processRequest(req));
});
