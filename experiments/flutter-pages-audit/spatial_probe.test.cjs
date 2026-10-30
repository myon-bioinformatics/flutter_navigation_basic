'use strict';
const test=require('node:test'),assert=require('node:assert/strict');
const {runSpatialProbe}=require('./spatial_probe.cjs');
function mock(failPhase=null){
 let size={width:390,height:500},time=0;const sizes=[],captures=[];
 const page={viewportSize:()=>size,setViewportSize:async value=>{size=value;sizes.push(value);},waitForTimeout:async()=>{},evaluate:async()=>({sampleMs:++time,observedRoute:'/screen136',viewport:{x:0,y:0,...size},nodes:[],scrollRegions:[],document:{},rawTruncated:false,enumerationComplete:true,nativeEnumerationComplete:true})};
 const source={route:'/screen136',referenceSha:'a'.repeat(40),sourceHashes:{'s.dart':'b'.repeat(64)},locale:'eng',stateKey:'initial',referenceHeights:[1600,1720]};
 return {args:{page,source,viewport:{width:390,height:500},geometry:async()=>({envelope:{x:0,y:56,width:390,height:size.height-80},headerFrame:{x:0,y:0,width:390,height:56},footerMode:'absent'}),settle:async()=>{},capture:async phase=>{captures.push(phase);if(phase===failPhase)throw Error('test screenshot failure');return{file:phase+'.png',sha256:'c'.repeat(64),bytes:10};}},sizes,captures};
}
test('bounded probe captures four phases and restores original viewport without retries',async()=>{const m=mock();const r=await runSpatialProbe(m.args);assert(r.complete);assert.equal(m.captures.length,4);assert.deepEqual(m.sizes,[{width:390,height:1600},{width:390,height:1720},{width:390,height:500}]);});
test('capture failure preserves error and restores; no implicit repeat',async()=>{const m=mock('spatial-reference-1600');const r=await runSpatialProbe(m.args);assert.equal(r.complete,false);assert.equal(r.errors.length,1);assert.equal(m.captures.filter(p=>p==='spatial-reference-1600').length,1);assert.deepEqual(m.sizes.at(-1),{width:390,height:500});});
test('unreviewed reference sizes fail before page action',async()=>{const m=mock();m.args.source.referenceHeights=[800,900];await assert.rejects(runSpatialProbe(m.args),/budget/);assert.equal(m.sizes.length,0);});
test('source required before any capture',async()=>{const m=mock();delete m.args.source;await assert.rejects(runSpatialProbe(m.args));assert.equal(m.captures.length,0);});
