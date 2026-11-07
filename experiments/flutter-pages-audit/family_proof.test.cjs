'use strict';
const test = require('node:test'), assert = require('node:assert/strict');
const {fixture} = require('./spatial_fixture.cjs');
const {projectSource, resolveSpatialContract, evaluateFamilyProof} = require('./family_proof.cjs');
function proofFixture() {
  const [spec, first, restored, refs] = fixture();
  const source = {...structuredClone(spec), spatial: structuredClone(spec)};
  const phases = ['spatial-initial','spatial-reference-1600','spatial-reference-1720','spatial-restored'];
  const frames = [first, ...refs, restored].map((sample, i) => {
    sample.observedRoute = source.route;
    const afterCapture = structuredClone(sample); afterCapture.sampleMs++;
    return {phase: phases[i], sample, afterCapture, captureStable: true, capture: {file: `${i}.png`, sha256: 'a'.repeat(64), bytes: 50}};
  });
  return [source, {schema: 'family-proof-observations/1', spatial: {complete: true, errors: [], frames}}];
}
test('fully source-bound complete observations may prove finite fit', () => assert.equal(evaluateFamilyProof(...proofFixture()).status, 'proven'));
test('lossless part projection retains roles, identities, state and group metadata', () => {
 const contract = {groups:[{key:'field',identifier:'wrapper',parts:[{key:'input',label:'Sample',role:'textbox',identifier:'field-input',value:'',enabled:true}],containerKind:'input'}],initialState:{query:''},terminalGroup:'field'};
 const before=structuredClone(contract), result=projectSource(contract,{width:390});
 assert.deepEqual(result.items[0],{...contract.groups[0].parts[0],key:'field:input',sourceGroup:'field'});
 assert.equal(result.groups[0].identifier,'wrapper'); assert.equal(result.groups[0].containerKind,'input'); assert.deepEqual(contract,before);
});
test('source alternatives select only one explicit representation',()=>{const [source,obs]=proofFixture();const item=source.spatial.items[0];item.selectorAlternatives=[item.selector,{...item.selector,tag:'H2',type:'native'}];delete item.selector;assert.equal(evaluateFamilyProof(source,obs).status,'proven');});
const mutations = {
 missingSourceBinding:x=>delete x[0].spatial,
 sourceRouteContradiction:x=>x[0].spatial.route='/screen137',
 wrongObservedRoute:x=>x[1].spatial.frames[0].sample.observedRoute='/screen137',
 incomplete:x=>x[1].spatial.complete=false,
 captureNotStable:x=>x[1].spatial.frames[0].captureStable=false,
 forgedStableFlag:x=>x[1].spatial.frames[0].afterCapture.nodes[2].box.height=11,
 captureBeforeMeasure:x=>x[1].spatial.frames[0].afterCapture.sampleMs=0,
 missingCapture:x=>delete x[1].spatial.frames[0].capture,
 duplicateCapture:x=>x[1].spatial.frames[1].capture.file='0.png',
 missingPhase:x=>x[1].spatial.frames[1].phase='other',
 driverError:x=>x[1].spatial.errors.push({message:'capture failed'}),
 staleBuild:x=>x[1].spatial.frames[0].sample.referenceSha='e'.repeat(40),
 fabricatedRole:x=>{const item=x[0].spatial.items[0];item.selectorAlternatives=[{...item.selector,role:'other'}];delete item.selector;},
 ambiguousAlternative:x=>{const item=x[0].spatial.items[0];item.selectorAlternatives=[item.selector,item.selector];delete item.selector;},
};
for(const [name,mutate] of Object.entries(mutations))test(name+' remains unverified',()=>{const f=proofFixture();mutate(f);assert.equal(evaluateFamilyProof(...f).status,'unverified');});
test('no source proof produces explicit unknown, not a vacuous pass',()=>assert.equal(evaluateFamilyProof({route:'/screen3',unresolved:['full terminal binding']},{schema:'family-proof-observations/1'}).status,'unverified'));
test('source-padding candidate never becomes a spatial pass',()=>assert.notEqual(evaluateFamilyProof({route:'/x',terminal:{}},{schema:'family-proof-observations/1',terminal:{}}).status,'proven'));
function nativeTextFixture(change) {
 const f=proofFixture();
 for(const frame of f[1].spatial.frames) {
  for(const sample of [frame.sample,frame.afterCapture]) {
   const owner=sample.nodes.find(n=>n.id==='status');
   const text={...structuredClone(owner),id:'native-status',type:'native',tag:'SPAN',ancestorIds:['status','root']};
   if(change)change(text);
   sample.nodes.push(text);sample.nativeCount++;
  }
 }
 return f;
}
test('exact inert native text descendant remains bound to its source semantic owner',()=>assert.equal(evaluateFamilyProof(...nativeTextFixture()).status,'proven'));
for(const [name,change] of Object.entries({interactive:n=>n.contentEditable='true',role:n=>n.role='button',identifier:n=>n.identifier='unknown',wrongText:n=>n.label='another text',wrongOwner:n=>n.ancestorIds=['root'],nativeInput:n=>n.tag='INPUT'}))test('native text '+name+' cannot hide unbound content/control',()=>assert.equal(evaluateFamilyProof(...nativeTextFixture(change)).status,'unverified'));
