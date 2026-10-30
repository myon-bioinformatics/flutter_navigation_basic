'use strict';
const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm');
const {collectSpatialInventory:collect}=require('./spatial_collector.cjs');
const text=value=>({nodeType:3,textContent:value});
class Element {
  constructor(tag,id='',attrs={},box={x:0,y:0,width:390,height:500}) {
    Object.assign(this,{tagName:tag,id,attrs,box,children:[],childNodes:[],parentElement:null,nodeType:1,
      offsetWidth:box.width,offsetHeight:box.height,clientWidth:box.width,clientHeight:box.height,clientLeft:0,clientTop:0,
      scrollWidth:box.width,scrollHeight:box.height,scrollLeft:0,scrollTop:0,
      css:{overflowX:'visible',overflowY:'visible',display:'block',visibility:'visible',opacity:'1',clipPath:'none',maskImage:'none',transform:'none',clip:'auto',fontSize:'16px',colorScheme:'normal'}});
  }
  append(e){e.parentElement=this;e._root=this.getRootNode();this.children.push(e);this.childNodes.push(e);return e;}
  getAttribute(k){return Object.hasOwn(this.attrs,k)?this.attrs[k]:null;}
  getBoundingClientRect(){return {...this.box};}
  getRootNode(){return this._root||{host:null};}
  matches(s){return s===':disabled'&&(this.disabled===true||this.parentElement?.tagName==='FIELDSET'&&this.parentElement.disabled===true);}
}
function fixture(fn) {
  const html=new Element('HTML','html'),body=html.append(new Element('BODY','body'));
  const view=body.append(new Element('FLUTTER-VIEW','view'));
  const root=view.append(new Element('FLT-SEMANTICS','root'));
  const status=root.append(new Element('FLT-SEMANTICS','status',{}, {x:0,y:56,width:80,height:20}));status.childNodes=[text('未実行')];
  const button=root.append(new Element('FLT-SEMANTICS','execute',{role:'button'},{x:0,y:76,width:80,height:32}));button.childNodes=[text('実行')];
  const back=root.append(new Element('FLT-SEMANTICS','back',{role:'button','aria-label':'Back'},{x:0,y:8,width:40,height:40}));
  const doc={children:[html],documentElement:html,activeElement:body,visibilityState:'visible',fonts:{status:'loaded'}};
  const globals={document:doc,innerWidth:390,innerHeight:500,getComputedStyle:e=>e.css,location:{pathname:'/app/',hash:'#/screen136',search:''},devicePixelRatio:1,visualViewport:{scale:1}};
  const saved={};for(const [k,v] of Object.entries(globals)){saved[k]=global[k];global[k]=v;}
  const context={route:'/screen136',referenceSha:'a'.repeat(40),sourceHashes:{'body.dart':'b'.repeat(64)},locale:'eng',stateKey:'initial',
    header:{x:0,y:0,width:390,height:56},envelope:{x:0,y:56,width:390,height:420},footer:null};
  try{return fn({html,body,view,root,status,button,back,doc,context});}
  finally {for(const [k,v] of Object.entries(saved))if(v===undefined)delete global[k];else global[k]=v;}
}
const byDom=(r,id)=>r.nodes.find(n=>n.domId===id);
test('browser-evaluable collector has no module-scope dependencies',()=>fixture(({context})=>{
  const browserFunction=vm.runInThisContext('('+collect.toString()+')');assert.equal(browserFunction(context).schema,'source-spatial-observation/1');
}));
test('complete raw semantics include header; no acceptance is inferred',()=>fixture(({context,root})=>{
  const r=collect(context);assert.equal(r.enumerationComplete,true);assert.equal(r.nativeEnumerationComplete,true);
  assert.equal(r.semanticCount,4);assert.equal(r.nativeCount,0);assert.equal(r.nodes.length,4);assert.equal(r.observedRoute,'/screen136');
  assert.equal(byDom(r,'status').label,'未実行');assert.equal(byDom(r,'execute').enabled,true);
  assert(!Object.hasOwn(byDom(r,'root'),'enabled'));assert(!Object.hasOwn(byDom(r,'status'),'enabled'));
  assert.deepEqual(byDom(r,'status').ancestorIds,[byDom(r,'root').id]);assert.equal(root.children.length,3);
  assert(!('acceptancePromoted' in r));assert(!('status' in r));assert.equal(r.displayObservation.flutterThemeObserved,false);
}));
test('stable private IDs survive viewport capture, not DOM replacement or duplicate dom IDs',()=>fixture(({context,root,status})=>{
  const first=collect(context);const before=byDom(first,'status').id;global.innerHeight=1600;assert.equal(byDom(collect(context),'status').id,before);
  const duplicate=root.append(new Element('FLT-SEMANTICS','status',{'aria-label':'Other'}));
  const next=collect(context);assert.equal(next.nodes.filter(n=>n.domId==='status').length,2);assert.equal(new Set(next.nodes.map(n=>n.id)).size,next.nodes.length);
  assert.notEqual(next.nodes.find(n=>n.label==='Other').id,before);assert.equal(status.id,duplicate.id);
}));
test('aria label including explicit empty label takes precedence, interior text whitespace remains exact',()=>fixture(({context,status})=>{
  status.childNodes=[text('未 実行')];assert.equal(byDom(collect(context),'status').label,'未 実行');
  status.attrs['aria-label']='overridden';assert.equal(byDom(collect(context),'status').label,'overridden');
  status.attrs['aria-label']='';assert.equal(byDom(collect(context),'status').label,'');
}));
test('semantic children do not give their label to structural ancestors',()=>fixture(({context})=>{
  assert.equal(byDom(collect(context),'root').label,'');
}));
test('native input is collected without role, with measured value and state',()=>fixture(({context,root})=>{
  const input=root.append(new Element('INPUT','input',{}, {x:0,y:120,width:100,height:32}));Object.assign(input,{value:'',type:'text',disabled:false});
  const r=collect(context),n=byDom(r,'input');assert.equal(r.nativeCount,1);assert.equal(n.role,null);assert.equal(n.value,'');assert.equal(n.enabled,true);assert.equal(n.inputType,'text');
}));
test('native select option states and checkbox state are measured',()=>fixture(({context,root})=>{
  const select=root.append(new Element('SELECT','select'));select.value='a';
  const option=select.append(new Element('OPTION','option'));option.selected=true;option.childNodes=[text('A')];
  const checkbox=root.append(new Element('INPUT','check'));checkbox.type='checkbox';checkbox.checked=true;checkbox.value='on';
  const r=collect(context);assert.equal(byDom(r,'select').value,'a');assert.equal(byDom(r,'option').selected,true);assert.equal(byDom(r,'check').checked,true);
}));
test('contenteditable and selectable native text leaves are preserved without duplicate wrapper invention',()=>fixture(({context,status})=>{
  status.childNodes=[];const wrapper=status.append(new Element('DIV','wrapper'));
  const span=wrapper.append(new Element('SPAN','selectable'));span.childNodes=[text('select me')];span.css.userSelect='text';
  const edit=wrapper.append(new Element('DIV','edit',{'contenteditable':'true'}));edit.childNodes=[text('edit me')];
  const r=collect(context);assert(byDom(r,'selectable'));assert(byDom(r,'edit'));assert(!byDom(r,'wrapper'));
  assert.equal(byDom(r,'edit').value,'edit me');assert.equal(byDom(r,'edit').enabled,true);
}));
test('disabled fieldset state is honored by native selector, aria state stays typed',()=>fixture(({context,root,button})=>{
  const field=root.append(new Element('FIELDSET','fieldset'));field.disabled=true;
  const input=field.append(new Element('INPUT','input'));input.value='x';
  button.attrs['aria-selected']='true';button.attrs['aria-checked']='mixed';button.attrs['aria-expanded']='false';
  const r=collect(context);assert.equal(byDom(r,'input').enabled,false);assert.equal(byDom(r,'execute').selected,true);assert.equal(byDom(r,'execute').checked,'mixed');assert.equal(byDom(r,'execute').expanded,false);
}));
test('open shadow-root native controls include host semantic ancestry',()=>fixture(({context,root})=>{
  const shadow={host:root,children:[]};root.shadowRoot=shadow;
  const input=new Element('INPUT','shadow-input');input.value='shadow';input._root=shadow;shadow.children.push(input);
  const n=byDom(collect(context),'shadow-input');assert(n);assert.equal(n.ancestorIds.length,1);assert.equal(n.value,'shadow');
}));
test('unknown custom element without inspectable shadow is explicit incomplete boundary',()=>fixture(({context,body})=>{
  body.append(new Element('UNKNOWN-WIDGET','opaque'));
  const r=collect(context);assert.equal(r.enumerationComplete,false);assert.equal(r.nativeEnumerationComplete,false);assert.equal(r.opaqueBoundaries.length,1);
}));
test('iframe and inaccessible embedded content never claim complete enumeration',()=>fixture(({context,body})=>{
  body.append(new Element('IFRAME','embedded'));assert.equal(collect(context).enumerationComplete,false);
}));
test('partial clip remains actual positive intersection with full viewport witness',()=>fixture(({context,root})=>{
  root.css.overflowY='hidden';root.clientHeight=90;root.scrollHeight=500;
  const n=byDom(collect(context),'execute');assert.equal(n.clip.height,90);assert.equal(n.box.height,32);assert.equal(n.ancestorClips.length,2);assert.equal(n.clipEnumerationComplete,true);
}));
test('axis-specific overflow does not fabricate clipping on visible axis',()=>fixture(({context,root})=>{
  root.css.overflowY='hidden';root.clientHeight=90;root.clientWidth=100;
  const n=byDom(collect(context),'execute');assert.equal(n.clip.width,390);assert.equal(n.clip.height,90);
}));
test('border/client clip uses measured client frame rather than outer border box',()=>fixture(({context,root})=>{
  root.css.overflowY='hidden';root.clientTop=3;root.clientHeight=90;
  const n=byDom(collect(context),'execute');assert.equal(n.clip.y,3);assert.equal(n.clip.height,90);
}));
test('self clip-path, rotation and inaccessible client geometry remain explicit',()=>fixture(({context,button,root})=>{
  button.css.clipPath='circle(1px)';assert.equal(byDom(collect(context),'execute').unsupportedClip,true);
  button.css.clipPath='none';button.css.transform='matrix(0,1,-1,0,0,0)';assert.equal(byDom(collect(context),'execute').unsupportedClip,true);
  button.css.transform='none';root.css.overflowY='hidden';root.offsetHeight=0;
  const n=byDom(collect(context),'execute');assert.equal(n.unsupportedClip,true);assert.equal(n.clipEnumerationComplete,false);
}));
test('hidden and opacity-zero nodes remain raw evidence rather than silently excluded',()=>fixture(({context,button})=>{
  button.css.opacity='0';const r=collect(context);assert(byDom(r,'execute'));assert.equal(byDom(r,'execute').visible,false);
}));
test('non-semantic scrolling ancestors and horizontal extents are retained',()=>fixture(({context,view})=>{
  view.css.overflowX='auto';view.scrollWidth=2000;
  const r=collect(context);assert.equal(r.scrollRegions.length,1);assert.equal(r.scrollRegions[0].scrollWidth,2000);assert.deepEqual(byDom(r,'execute').scrollAncestorIds,[r.scrollRegions[0].id]);
}));
test('missing driver chrome is explicit incomplete context, never guessed from labels',()=>fixture(({context})=>{
  delete context.header;const r=collect(context);assert.equal(r.header,null);assert.equal(r.enumerationComplete,false);assert(r.problems.length);
}));
test('declared route/locale/state remain separate from observed route and document display',()=>fixture(({context,html})=>{
  context.route='/wrong';context.locale='jpn';html.lang='en';global.location.hash='#/screen136?ignored=1';
  const r=collect(context);assert.equal(r.route,'/wrong');assert.equal(r.observedRoute,'/screen136');assert.equal(r.displayObservation.documentLang,'en');assert.equal(r.locale,'jpn');
}));
test('node cap never claims a complete traversal or drops count evidence',()=>fixture(({context,root})=>{
  for(let i=0;i<4001;i++)root.append(new Element('FLT-SEMANTICS','extra'+i));
  const r=collect(context);assert.equal(r.nodes.length,4000);assert(r.observedCandidateCount>4000);assert.equal(r.rawTruncated,true);assert.equal(r.enumerationComplete,false);
}));
test('document root extents and active element are measured, not replaced by viewport values',()=>fixture(({context,html,doc,button})=>{
  html.scrollHeight=700;doc.activeElement=button;const r=collect(context);assert.equal(r.document.scrollHeight,700);assert.equal(r.document.clientHeight,500);assert.equal(r.displayObservation.activeElement.domId,'execute');
}));

test('password values are never captured in raw evidence',()=>fixture(({context,root})=>{
  const input=root.append(new Element('INPUT','password'));input.type='password';input.value='secret';
  const result=collect(context),n=byDom(result,'password');assert.equal(n.value,null);assert.equal(n.valueRedacted,true);assert(!JSON.stringify(result).includes('secret'));
}));
test('unknown Flutter-prefixed custom hosts do not bypass opaque boundary detection',()=>fixture(({context,body})=>{
  body.append(new Element('FLT-UNKNOWN-WIDGET','opaque'));assert.equal(collect(context).enumerationComplete,false);
}));
test('rounded clipping is unsupported rather than treated as a complete rectangle',()=>fixture(({context,root})=>{
  root.css.overflowY='hidden';root.css.borderTopLeftRadius='8px';assert.equal(byDom(collect(context),'execute').unsupportedClip,true);
}));

test('text and native link outside Flutter are retained as unaccounted content, not ignored',()=>fixture(({context,body})=>{
  const textLeaf=body.append(new Element('P','outside'));textLeaf.childNodes=[text('unexpected outside text')];
  body.append(new Element('A','link',{href:'/elsewhere'}));const r=collect(context);assert(byDom(r,'outside'));assert(byDom(r,'link'));assert.equal(byDom(r,'link').enabled,true);
}));

test('raw descendant census and scroll transform stay measured and include native children',()=>fixture(({context,root,view})=>{
  const input=root.append(new Element('INPUT','child'));input.value='';view.css.overflowY='auto';
  const r=collect(context),n=byDom(r,'root');assert(n.rawDescendantIds.includes(byDom(r,'child').id));assert.equal(n.descendantEnumerationComplete,true);assert.equal(r.scrollRegions[0].transform,'none');
}));

test('mixed direct text wrapper and child text both remain in the raw census',()=>fixture(({context,body})=>{
  const wrapper=body.append(new Element('DIV','mixed'));wrapper.childNodes=[text('unaccounted wrapper text ')];
  const child=wrapper.append(new Element('SPAN','mixed-child'));child.childNodes=[text('known child text')];
  const r=collect(context),n=byDom(r,'mixed');assert(n);assert.equal(n.directText,'unaccounted wrapper text');
  assert.equal(n.label,'unaccounted wrapper text known child text');assert(byDom(r,'mixed-child'));
  assert.notEqual(n.id,byDom(r,'mixed-child').id);assert.equal(r.nativeCount,2);
}));
test('mixed direct text beside semantic child cannot disappear',()=>fixture(({context,body})=>{
  const wrapper=body.append(new Element('DIV','mixed'));wrapper.childNodes=[text('unexpected direct text')];
  wrapper.append(new Element('FLT-SEMANTICS','known',{'aria-label':'Known'}));
  const r=collect(context);assert.equal(byDom(r,'mixed').label,'unexpected direct text');assert(byDom(r,'known'));
}));
for(const tag of ['IMG','VIDEO','AUDIO','CANVAS','PICTURE','svg','image','HR','METER','PROGRESS']) {
  test(`visible replaced ${tag} content is retained even without label/role/text`,()=>fixture(({context,body})=>{
    body.append(new Element(tag,'unaccounted-replaced',{}, {x:100,y:120,width:120,height:80}));
    const r=collect(context),n=byDom(r,'unaccounted-replaced');assert(n);assert.equal(n.type,'native');assert.equal(n.replacedContent,true);
    assert.equal(n.label,'');assert.equal(n.role,null);assert.equal(n.box.width,120);assert.equal(r.nativeCount,1);
    assert(!Object.hasOwn(n,'enabled'));assert(!('acceptancePromoted' in r));
  }));
}
test('embedded replaced content retained alongside explicit incomplete boundary',()=>fixture(({context,body})=>{
  body.append(new Element('IFRAME','unaccounted-frame'));const r=collect(context);
  assert.equal(byDom(r,'unaccounted-frame').replacedContent,true);assert.equal(r.enumerationComplete,false);
}));
