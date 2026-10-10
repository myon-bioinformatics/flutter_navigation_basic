// Portable bounded concurrency examples for patterns 138-143.
// Node.js 22+ standard APIs only; does not implement Flutter isolate semantics.
import {readFileSync} from 'node:fs';
import {pathToFileURL} from 'node:url';
function check(ok,msg){if(!ok)throw new TypeError(msg);}
function tasks(raw){
 check(Array.isArray(raw)&&raw.length<=32,'tasks must be an array (max 32)');
 return raw.map((item,i)=>{
  check(item!==null&&typeof item==='object'&&!Array.isArray(item),'task object required');
  check(Object.keys(item).every(k=>['value','delay_ms'].includes(k))&&Object.hasOwn(item,'value'),'task keys');
  const delay=item.delay_ms??0;
  check(Number.isInteger(delay)&&delay>=0&&delay<=50,'delay_ms must be 0..50');
  return {value:item.value,delay,index:i};
 });
}
function latency(job){return new Promise(resolve=>setTimeout(()=>resolve(job.value),job.delay));}
async function scheduled(jobs,limit){
 check(Number.isInteger(limit)&&limit>=1&&limit<=32,'concurrency 1..32');
 let next=0,active=0,peak=0;
 const results=new Array(jobs.length);
 async function worker(){
  while(next<jobs.length){
   const j=jobs[next++];active++;peak=Math.max(peak,active);
   try{results[j.index]=await latency(j);}
   finally{active--;}
  }
 }
 await Promise.all(Array.from({length:Math.min(limit,jobs.length)},worker));
 return {values:results,max_active:peak};
}
export async function processRequest(request){
 check(request&&typeof request==='object'&&!Array.isArray(request),'request object');
 const mode=request.mode;
 check(['work_queue','semaphore','mutex','cancelable','parallel_map','progress'].includes(mode),'unsupported mode');
 const allowed=mode==='cancelable'?['mode','task','cancel']:
  mode==='mutex'?['mode','increments']:
  ['mode','tasks',...(mode==='semaphore'||mode==='parallel_map'?['concurrency']:[])];
 check(Object.keys(request).every(k=>allowed.includes(k)),'unknown request keys');
 let result;
 if(mode==='mutex'){
  const inc=request.increments;
  check(Array.isArray(inc)&&inc.length<=32&&inc.every(x=>Number.isSafeInteger(x)),'increments');
  let state=0;const history=[];
  // Serialized critical section: each update observes the last committed state.
  for(const n of inc){state+=n;check(Number.isSafeInteger(state),'overflow');history.push(state);}
  result={value:state,history};
 }else if(mode==='cancelable'){
  const list=tasks([request.task]);check(typeof request.cancel==='boolean','cancel flag required');
  const controller=new AbortController();
  if(request.cancel)controller.abort();
  const job=list[0];
  result=await new Promise(resolve=>{
   if(controller.signal.aborted){resolve({status:'cancelled'});return;}
   const timer=setTimeout(()=>resolve({status:'completed',value:job.value}),job.delay);
   controller.signal.addEventListener('abort',()=>{clearTimeout(timer);resolve({status:'cancelled'});},{once:true});
  });
 }else{
  const jobs=tasks(request.tasks);
  const n=mode==='work_queue'||mode==='progress'?1:
    mode==='semaphore'||mode==='parallel_map'?request.concurrency:1;
  const metrics=await scheduled(jobs,n);
  if(mode==='progress')result={values:metrics.values,progress:jobs.map((_,i)=>({completed:i+1,total:jobs.length}))};
  else result=metrics;
 }
 return {schema:'concurrency-patterns/1',mode,result};
}
async function main(){
 try{
  const args=process.argv.slice(2);
  check(args.length===0||(args.length===2&&args[0]==='--input'&&args[1]),'usage: --input path');
  const input=args.length?readFileSync(args[1],'utf8'):readFileSync(0,'utf8');
  process.stdout.write(JSON.stringify(await processRequest(JSON.parse(input)))+'\n');
 }catch(e){process.stderr.write('invalid input: '+e.message+'\n');process.exitCode=2;}
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href)await main();
