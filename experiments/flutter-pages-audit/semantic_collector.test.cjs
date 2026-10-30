'use strict';
const test=require('node:test'),assert=require('node:assert/strict');
const {collectSemanticInventory:collect}=require('./semantic_collector.cjs');
class Element {
 constructor(id,attrs={},rect={x:0,y:56,width:390,height:400}){Object.assign(this,{id,attrs,rect,tagName:'FLT-SEMANTICS',children:[],parentElement:null,css:{overflowX:'visible',overflowY:'visible',clipPath:'none'},scrollTop:0,scrollHeight:400,clientHeight:400});}
 append(c){c.parentElement=this;this.children.push(c);return c;}
 getAttribute(k){return this.attrs[k]??null;}
 getBoundingClientRect(){return this.rect;}
 contains(n){return n===this||this.children.some(c=>c.contains(n));}
 descendants(){return this.children.flatMap(c=>[c,...c.descendants()]);}
 isChrome(){const i=this.attrs['flt-semantics-identifier']||'';return i.startsWith('shared-header-')||i==='tool-door-dropdown';}
 closest(){for(let p=this;p;p=p.parentElement)if(p.isChrome())return p;return null;}
 querySelector(selector){return this.descendants().find(c=>selector==='flt-semantics'||(c.attrs['flt-semantics-identifier']||'').startsWith('shared-header-'))||null;}
}
function fixture(fn){
 const page=new Element('page',{}, {x:0,y:0,width:390,height:500}),header=page.append(new Element('header',{'flt-semantics-identifier':'shared-header-title'})),body=page.append(new Element('body'));
 const status=body.append(new Element('s',{'aria-label':'未実行'},{x:0,y:56,width:80,height:24}));
 const button=body.append(new Element('b',{'aria-label':'実行',role:'button'},{x:0,y:80,width:80,height:40}));
 const saved={};for(const k of ['document','innerWidth','innerHeight','getComputedStyle'])saved[k]=global[k];
 global.innerWidth=390;global.innerHeight=500;global.getComputedStyle=e=>e.css;global.document={querySelectorAll:()=>[page,...page.descendants()],documentElement:{scrollWidth:390,scrollHeight:500}};
 const spec={items:[{key:'status',label:'未実行'},{key:'button',label:'実行',role:'button'}],groups:[{key:'body',keys:['status','button']}]};
 try{return fn({page,header,body,status,button,spec});}finally{for(const[k,v]of Object.entries(saved))if(v===undefined)delete global[k];else global[k]=v;}
}
test('read-only collector records source inventory and complete measured ancestry without asserting acceptance',()=>fixture(({spec,body})=>{const r=collect(spec);assert.deepEqual(r.items.map(i=>i.count),[1,1]);assert.equal(r.bodyRoot.id,'body');assert.equal(r.bodyRootContainsChrome,false);assert.equal(r.completeOutsideChromeLeafInventory.length,2);assert(r.completeOutsideChromeLeafInventory.every(l=>l.covered));assert.deepEqual(r.items[0].nodes[0].ancestorIds,['body','page']);assert.equal(r.groups[0].container.id,'body');assert(!('status'in r));assert.equal(body.children.length,2);}));
test('duplicate expected label remains ambiguous',()=>fixture(({spec,body})=>{body.append(new Element('dup',{'aria-label':'未実行'}));const r=collect(spec);assert.equal(r.items[0].count,2);assert.equal(r.bodyRoot,null);}));
test('unlisted semantic leaf is retained as uncovered',()=>fixture(({spec,body})=>{body.append(new Element('extra',{'aria-label':'unreviewed'}));const r=collect(spec);assert.equal(r.completeOutsideChromeLeafInventory.find(x=>x.id==='extra').covered,false);}));
test('clipping ancestor intersects actual box and unsupported clip is explicit',()=>fixture(({spec,body})=>{body.css.overflowY='hidden';body.rect.height=30;body.css.clipPath='circle(10px)';const r=collect(spec);assert.equal(r.items[1].nodes[0].clip.height,30);assert.equal(r.items[1].nodes[0].unsupportedClip,true);}));
test('shared ancestor containing header cannot masquerade as isolated body',()=>fixture(({spec,page,body,button})=>{body.children=body.children.filter(c=>c!==button);page.append(button);assert.equal(collect(spec).bodyRootContainsChrome,true);}));
test('missing label or wrong role records zero and no invented root',()=>fixture(({spec,button})=>{button.attrs.role='text';const r=collect(spec);assert.equal(r.items[1].count,0);assert.equal(r.bodyRoot,null);}));
test('source-defined identifiers distinct from keys; no arbitrary selectors accepted',()=>fixture(({spec,button})=>{button.attrs['flt-semantics-identifier']='known';spec.items[1]={key:'button',identifier:'known'};assert.equal(collect(spec).items[1].count,1);assert.throws(()=>collect({items:[{key:'x',selector:'*'}]}),/inventory/);}));

test('self clip-path and hidden semantics are explicit blockers',()=>fixture(({spec,button})=>{button.css.clipPath='circle(1px)';button.attrs['aria-hidden']='true';const n=collect(spec).items[1].nodes[0];assert.equal(n.unsupportedClip,true);assert.equal(n.visible,false);}));
test('horizontal scroller is retained even without vertical overflow',()=>fixture(({spec,body})=>{body.css.overflowX='auto';body.scrollWidth=2000;assert.equal(collect(spec).scrollRegions.length,1);}));
test('unlisted child under selected container is not declared complete',()=>fixture(({spec,status})=>{status.append(new Element('unexpected',{'aria-label':'extra'}));const r=collect(spec);assert.equal(r.completeOutsideChromeLeafInventory.find(x=>x.id==='unexpected').covered,false);}));
test('actual runner binding projection supplies all 48 source inventories without missing or duplicate keys',()=>{
 const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
 const manifest=JSON.parse(fs.readFileSync(path.join(__dirname,'family-inventory.json'),'utf8'));
 const src=fs.readFileSync(path.join(__dirname,'audit.spec.cjs'),'utf8');
 const start=src.indexOf('function familySpec('),end=src.indexOf('const familyTestInfo',start);
 assert(start>=0&&end>start);const project=vm.runInNewContext(src.slice(start,end)+';familySpec',{familyManifest:manifest,projectSource:require('./family_proof.cjs').projectSource});
 for(const contract of manifest.contracts)for(const width of[390,1180]){
  const s=project(contract.route,{width});assert(s.items.length>0);assert.equal(new Set(s.items.map(x=>x.key)).size,s.items.length);
  for(const i of s.items)assert((typeof i.label==='string'&&i.label)||(Array.isArray(i.labelAny)&&i.labelAny.length)||(typeof i.identifier==='string'&&i.identifier));
  for(const g of s.groups)assert(g.keys.length>0&&g.keys.every(k=>s.items.some(i=>i.key===k)));
 }
 assert.throws(()=>project('/unreviewed',{width:390}),/outside explicit/);
});

const textNode=value=>({nodeType:3,textContent:value});
test('DOM text labels are recorded and exactly matched without granting acceptance',()=>fixture(({spec,status,button})=>{
 delete status.attrs['aria-label'];status.childNodes=[textNode('未実行')];
 delete button.attrs['aria-label'];button.childNodes=[{nodeType:1,tagName:'SPAN',childNodes:[textNode('実行')]}];
 const r=collect(spec);assert.deepEqual(r.items.map(i=>i.count),[1,1]);
 assert.equal(r.items[0].nodes[0].label,null);assert.equal(r.items[0].nodes[0].text,'未実行');
 assert.equal(r.items[0].nodes[0].matchedLabel,'未実行');assert(!('status' in r));
}));
test('explicit aria label takes precedence over different DOM text',()=>fixture(({spec,status})=>{
 status.childNodes=[textNode('実行')];assert.equal(collect(spec).items[0].count,1);
 status.attrs['aria-label']='different';assert.equal(collect(spec).items[0].count,0);
}));
test('semantic descendant text is not inherited; repeated own text remains ambiguous',()=>fixture(({spec,body,status})=>{
 delete status.attrs['aria-label'];status.childNodes=[textNode('未実行')];
 body.childNodes=[Object.assign(status,{nodeType:1})];assert.equal(collect(spec).items[0].count,1);
 const dup=body.append(new Element('duplicate'));dup.childNodes=[textNode('未実行')];
 assert.equal(collect(spec).items[0].count,2);assert.equal(collect(spec).bodyRoot,null);
}));
test('DOM text fallback preserves interior whitespace and role checks',()=>fixture(({spec,status,button})=>{
 delete status.attrs['aria-label'];status.childNodes=[textNode('未 実行')];
 delete button.attrs['aria-label'];button.childNodes=[textNode('実行')];button.attrs.role='text';
 assert.deepEqual(collect(spec).items.map(i=>i.count),[0,0]);
}));
