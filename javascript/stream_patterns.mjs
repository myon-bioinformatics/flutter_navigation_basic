import {readFileSync} from 'node:fs';
import {pathToFileURL} from 'node:url';
const modes=['basic','controller','broadcast','transform','merge','debounce','throttle','buffer','window'];
function check(ok,msg){if(!ok)throw new TypeError(msg);}
function events(xs){check(Array.isArray(xs)&&xs.length<=1000,'events must be array <=1000');let last=-1;return xs.map(x=>{check(x&&typeof x==='object'&&!Array.isArray(x)&&Object.keys(x).sort().join()==='at_ms,value','event shape');check(Number.isInteger(x.at_ms)&&x.at_ms>=last&&x.at_ms<=60000,'sorted event time');last=x.at_ms;return x;});}
async function* stream(xs){for(const x of xs)yield x;}
async function collect(xs){const a=[];for await(const x of stream(xs))a.push(x);return a;}
export async function processRequest(req){
 check(req&&typeof req==='object'&&!Array.isArray(req)&&modes.includes(req.mode),'mode');
 const mode=req.mode;let xs=[];
 if(mode==='controller'){
  check(Array.isArray(req.commands)&&req.commands.length<=1000,'commands');
  let closed=false;for(const cmd of req.commands){check(cmd&&typeof cmd==='object','command');if(cmd.op==='close'){check(!closed,'closed twice');closed=true;}else{check(cmd.op==='add'&&!closed&&Object.hasOwn(cmd,'value'),'invalid add');xs.push({at_ms:xs.length,value:cmd.value});}}check(closed,'close required');
 }else if(mode==='merge'){
  check(Array.isArray(req.streams)&&req.streams.length>0&&req.streams.length<=16,'streams');
  xs=req.streams.flatMap((s,i)=>events(s).map((x,j)=>({...x,source:i,index:j}))).sort((a,b)=>a.at_ms-b.at_ms||a.source-b.source||a.index-b.index).map(({index,...x})=>x);
 }else xs=events(req.events);
 if(mode==='transform'){
  check(Array.isArray(req.steps)&&req.steps.length>0&&req.steps.length<=16,'steps');
  for(const step of req.steps){
   check(step&&typeof step==='object','step');
   if(step.op==='where_equals')xs=xs.filter(x=>JSON.stringify(x.value)===JSON.stringify(step.value));
   else if(step.op==='expand')xs=xs.flatMap(x=>{check(Array.isArray(x.value),'expand array');return x.value.map(value=>({...x,value}));});
   else if(step.op==='map_add')xs=xs.map(x=>{check(typeof x.value==='number'&&Number.isFinite(x.value)&&typeof step.value==='number'&&Number.isFinite(step.value),'map_add numbers');return {...x,value:x.value+step.value};});
   else check(false,'step operation');
  }
 }
 if(mode==='debounce'||mode==='throttle'){
  const ms=req.duration_ms;check(Number.isInteger(ms)&&ms>0&&ms<=60000,'duration');
  if(mode==='debounce')xs=xs.filter((x,i)=>!xs[i+1]||xs[i+1].at_ms-x.at_ms>ms);
  else{let last=-Infinity;xs=xs.filter(x=>{if(x.at_ms-last<ms)return false;last=x.at_ms;return true;});}
 }
 if(mode==='buffer'||mode==='window'){
  const n=req.size;check(Number.isInteger(n)&&n>0&&n<=1000,'size');
  const step=mode==='buffer'?n:(req.step??1);check(Number.isInteger(step)&&step>0&&step<=1000,'step');
  const out=[];for(let i=0;i<xs.length;i+=step){const part=xs.slice(i,i+n);if(mode==='window'&&part.length<n)break;if(!part.length)break;out.push({at_ms:part.at(-1).at_ms,value:part.map(x=>x.value)});}xs=out;
 }
 xs=await collect(xs);
 if(mode==='broadcast'){check(Number.isInteger(req.subscribers)&&req.subscribers>=1&&req.subscribers<=16,'subscribers');return {schema:'stream-patterns/1',mode,subscribers:Array.from({length:req.subscribers},()=>xs.map(x=>({...x})))};}
 return {schema:'stream-patterns/1',mode,events:xs};
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){
 try{const args=process.argv.slice(2);check(args.length===0||(args.length===2&&args[0]==='--input'),'arguments');const input=args.length?readFileSync(args[1],'utf8'):readFileSync(0,'utf8');process.stdout.write(JSON.stringify(await processRequest(JSON.parse(input)))+'\n');}
 catch(error){process.stderr.write('invalid input: '+error.message+'\n');process.exitCode=2;}
}
