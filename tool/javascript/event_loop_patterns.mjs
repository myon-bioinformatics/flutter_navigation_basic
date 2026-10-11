// Dependency-free Node 22+ reference for catalogue patterns 146–150.
// 144/145 reuse stream_patterns.mjs (event-time debounce/throttle).
import {readFileSync} from 'node:fs';
import {pathToFileURL} from 'node:url';
const fail = msg => { throw new TypeError(msg); };
function check(ok,msg){if(!ok)fail(msg);}
function rows(xs){
 check(Array.isArray(xs)&&xs.length<=1000,'values must be array <=1000');
 return xs;
}
function checkKeys(obj,allowed,required=[]){
 check(obj!==null&&typeof obj==='object'&&!Array.isArray(obj),'object required');
 check(Object.keys(obj).every(k=>allowed.includes(k)),'unknown field');
 check(required.every(k=>Object.hasOwn(obj,k)),'missing field');
}
async function* fromArray(values){for(const value of values) yield value;}
async function collect(iter){const out=[];for await(const value of iter)out.push(value);return out;}
export async function processRequest(req){
 checkKeys(req,['mode','values','pause_after','steps'],['mode','values']);
 const mode=req.mode, input=rows(req.values);
 check(['reactive','event_loop','microtask','suspend_resume','async_generator'].includes(mode),'unsupported mode');
 let result;
 if(mode==='reactive'){
  checkKeys(req,['mode','values','steps'],['mode','values','steps']);
  check(Array.isArray(req.steps)&&req.steps.length>0&&req.steps.length<=16,'steps');
  let values=input.slice();
  for(const step of req.steps){
   checkKeys(step,['op','value'],['op','value']);
   if(step.op==='map_add'){
    check(typeof step.value==='number'&&Number.isFinite(step.value)&&values.every(x=>typeof x==='number'&&Number.isFinite(x)),'numbers required');
    values=values.map(x=>x+step.value);
   }else if(step.op==='where_equals'){
    values=values.filter(x=>JSON.stringify(x)===JSON.stringify(step.value));
   }else fail('unsupported reactive step');
  }
  result=await collect(fromArray(values));
 }else if(mode==='event_loop'){
  checkKeys(req,['mode','values']);
  // Input values are trace annotations. Explicitly model microtask-before-timer.
  const trace=[];
  await new Promise(resolve=>{
   trace.push({phase:'sync',values:input});
   queueMicrotask(()=>trace.push({phase:'microtask',values:input}));
   setTimeout(()=>{trace.push({phase:'timer',values:input});resolve();},0);
  });
  result=trace;
 }else if(mode==='microtask'){
  checkKeys(req,['mode','values']);
  const trace=['sync'];
  queueMicrotask(()=>trace.push('microtask'));
  Promise.resolve().then(()=>trace.push('promise'));
  await new Promise(resolve=>setTimeout(()=>{trace.push('timer');resolve();},0));
  result=trace;
 }else if(mode==='suspend_resume'){
  checkKeys(req,['mode','values','pause_after'],['mode','values','pause_after']);
  check(Number.isInteger(req.pause_after)&&req.pause_after>=0&&req.pause_after<=input.length,'pause_after');
  const trace=[],values=[];
  let seen=0;
  for await(const value of fromArray(input)){
   if(seen===req.pause_after)trace.push('paused','resumed');
   values.push(value);seen++;
  }
  if(seen===req.pause_after)trace.push('paused','resumed');
  result={values,trace};
 }else{
  checkKeys(req,['mode','values']);
  result=await collect(fromArray(input));
 }
 return {schema:'event-loop-patterns/1',mode,result};
}
async function main(){
 try{const args=process.argv.slice(2);check(args.length===0||(args.length===2&&args[0]==='--input'&&args[1]),'usage: --input path');
 const raw=args.length?readFileSync(args[1],'utf8'):readFileSync(0,'utf8');
 process.stdout.write(JSON.stringify(await processRequest(JSON.parse(raw)))+'\n');
 }catch(e){process.stderr.write('invalid input: '+e.message+'\n');process.exitCode=2;}
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href)await main();
