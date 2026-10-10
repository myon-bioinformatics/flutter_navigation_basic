import test from 'node:test';
import assert from 'node:assert/strict';
import {processRequest} from '../concurrency_patterns.mjs';
const task=(value,delay_ms=0)=>({value,delay_ms});
test('138 work queue preserves submission order and serial execution',async()=>{
 const x=await processRequest({mode:'work_queue',tasks:[task('a',9),task('b'),task('c')]});
 assert.deepEqual(x.result,{values:['a','b','c'],max_active:1});
});
test('139 semaphore caps simultaneous work while retaining input order',async()=>{
 const x=await processRequest({mode:'semaphore',concurrency:2,tasks:[task(1,12),task(2,12),task(3)]});
 assert.deepEqual(x.result.values,[1,2,3]);assert.equal(x.result.max_active,2);
});
test('140 mutex critical section commits sequentially',async()=>{
 const x=await processRequest({mode:'mutex',increments:[3,-1,4]});
 assert.deepEqual(x.result,{value:6,history:[3,2,6]});
});
test('141 cancellation has no completion result when aborted',async()=>{
 assert.deepEqual((await processRequest({mode:'cancelable',task:task('a'),cancel:true})).result,{status:'cancelled'});
 assert.deepEqual((await processRequest({mode:'cancelable',task:task('a'),cancel:false})).result,{status:'completed',value:'a'});
});
test('142 parallel map limits workers and preserves results',async()=>{
 const x=await processRequest({mode:'parallel_map',concurrency:2,tasks:[task('slow',12),task('fast'),task('last')]});
 assert.deepEqual(x.result.values,['slow','fast','last']);assert.equal(x.result.max_active,2);
});
test('143 progress reports monotone completed task counts',async()=>{
 const x=await processRequest({mode:'progress',tasks:[task(1),task(2)]});
 assert.deepEqual(x.result.progress,[{completed:1,total:2},{completed:2,total:2}]);
});
test('invalid contracts fail closed',async()=>{
 for(const x of [{mode:'semaphore',tasks:[task(1)],concurrency:0},{mode:'work_queue',tasks:[task(1,-1)]},{mode:'cancelable',task:task(1),cancel:'true'},{mode:'mutex',increments:[1.5]},{mode:'parallel_map',tasks:[],concurrency:33}])await assert.rejects(processRequest(x));
});
