'use strict';
// LOCAL PURE PROTOTYPE. Not imported by production/audit; no browser input.
// trustedSource must be created/reviewed from pinned source, never page data.
const EPS = 1; // Existing geometry/restore tolerance, not a DOM residual waiver.
const finite = x => typeof x === 'number' && Number.isFinite(x);
const id = x => typeof x === 'string' && x.length > 0;
const unique = xs => Array.isArray(xs) && xs.length > 0 && xs.every(id) && new Set(xs).size === xs.length;
const box = b => b && ['x','y','width','height'].every(k => finite(b[k])) && b.width > 0 && b.height > 0;
const inside = (b, c) => box(b) && box(c) && b.x >= c.x && b.y >= c.y && b.x+b.width <= c.x+c.width && b.y+b.height <= c.y+c.height;
const near = (a,b) => finite(a) && finite(b) && Math.abs(a-b) <= EPS;
const equal = (a,b) => JSON.stringify(a) === JSON.stringify(b);
const shape = (a,b) => box(a) && box(b) && ['x','width','height'].every(k=>near(a[k],b[k]));
const sameBox = (a,b) => shape(a,b) && near(a.y,b.y);
const overlaps = (a,b) => box(a)&&box(b)&&Math.min(a.x+a.width,b.x+b.width)>Math.max(a.x,b.x)&&Math.min(a.y+a.height,b.y+b.height)>Math.max(a.y,b.y);
const binding = b => b && id(b.label) && (b.role===null||id(b.role)) && b.state && typeof b.state==='object' && !Array.isArray(b.state);
const hash = (x,n) => typeof x==='string' && new RegExp(`^[0-9a-f]{${n}}$`).test(x);
const residual = f => f.region.height-f.region.client-f.region.top;
const unknown = reason => ({status:'unverified', reason, proof:null});
function evaluateTerminal(trustedSource, observation) {
  const s=trustedSource, o=observation;
  if (!s || s.schema!=='source-terminal/1' || !id(s.route) || !s.route.startsWith('/') ||
      !hash(s.referenceSha,40) || !hash(s.sourceSha256,64) || !hash(s.stateSha256,64) ||
      !hash(s.runtimeSha256,64) || !id(s.layoutKey) || !s.initialState || typeof s.initialState!=='object' ||
      !unique(s.orderedItemKeys) || !unique(s.terminalPartKeys) || !unique(s.chromeIds) ||
      !binding(s.terminalBinding) || !s.partBindings || !s.terminalPartKeys.every(k=>binding(s.partBindings[k])) ||
      s.terminalKey!==s.orderedItemKeys.at(-1) || s.terminalIndex!==s.orderedItemKeys.length-1 ||
      !['dom-extent','source-padding-geometry'].includes(s.endMode)) return unknown('invalid-source-contract');
  if (s.endMode==='source-padding-geometry' &&
      (!finite(s.trailingPadding) || s.trailingPadding<0 || !hash(s.tailSourceSha256,64) ||
       s.tailStructure!=='only-declared-padding-after-terminal-container')) return unknown('unbound-tail-structure');
  if (!o || o.schema!=='terminal-observation/1' || !Array.isArray(o.frames) || o.frames.length!==5 ||
      !Array.isArray(o.inputs) || o.inputs.length!==4) return unknown('missing-observation');
  const [first,end,back,restored,stable]=o.frames;
  const r=o.reference;
  if (!r || r.schema!=='intrinsic-terminal-reference/1' || r.route!==s.route || r.referenceSha!==s.referenceSha ||
      r.sourceSha256!==s.sourceSha256 || r.stateSha256!==s.stateSha256 || r.runtimeSha256!==s.runtimeSha256 ||
      r.layoutKey!==s.layoutKey || !equal(r.state,s.initialState) || !hash(r.captureSha256,64) ||
      !box(r.viewport) || !box(r.container) || r.terminalKey!==s.terminalKey || r.terminalIndex!==s.terminalIndex ||
      !equal(r.binding,s.terminalBinding) || !id(r.containerId) || !unique(r.ancestorIds) || r.visible!==true ||
      r.unsupportedClip!==false || !inside(r.container,r.clip) || !Array.isArray(r.ancestorClips) ||
      r.ancestorClips.some(c=>!inside(r.container,c)) || !unique(r.rawDescendantIds) ||
      r.rawInventoryTruncated!==false || r.rawDescendantCount!==r.rawDescendantIds.length ||
      !Array.isArray(r.parts) || r.parts.length!==s.terminalPartKeys.length ||
      !unique(r.parts.map(p=>p?.key)) || !s.terminalPartKeys.every(k=>r.parts.some(p=>p.key===k)) ||
      !inside(r.container,r.viewport) || !unique(r.parts.map(p=>p?.id)) ||
      !equal([...r.rawDescendantIds].sort(),r.parts.map(p=>p.id).sort()) ||
      r.parts.some(p=>!inside(p.box,r.container)||!inside(p.box,p.clip)||p.visible!==true||p.unsupportedClip!==false||!Array.isArray(p.ancestorClips)||
        p.ancestorClips.some(c=>!inside(p.box,c))||!equal(p.binding,s.partBindings[p.key])||!unique(p.ancestorIds)||p.ancestorIds[0]!==r.containerId||
        !equal(p.ancestorIds.slice(1),r.ancestorIds))) return unknown('missing-intrinsic-reference');
  for (const [i,f] of o.frames.entries()) {
    if (!f || f.route!==s.route || f.referenceSha!==s.referenceSha || f.sourceSha256!==s.sourceSha256 ||
        f.stateSha256!==s.stateSha256 || f.runtimeSha256!==s.runtimeSha256 || f.layoutKey!==s.layoutKey ||
        !equal(f.state,s.initialState) || !hash(f.captureSha256,64) || !finite(f.sampleMs) ||
        (i && f.sampleMs<=o.frames[i-1].sampleMs) || !inside(f.envelope,f.viewport) ||
        !sameBox(f.viewport,first.viewport) || !sameBox(f.envelope,first.envelope) ||
        !near(r.viewport.width,f.viewport.width) || !f.region || !id(f.region.id) ||
        f.region.id!==first.region?.id || !sameBox(f.region.box,first.region.box) ||
        !inside(f.region.box,f.envelope) || ![f.region.top,f.region.height,f.region.client].every(finite) ||
        f.region.client<=0 || f.region.height<f.region.client || f.region.top<0 || residual(f)<0 ||
        f.region.height!==first.region.height || f.region.client!==first.region.client ||
        !near(f.region.box.height,f.region.client) || f.region.axis!=='vertical' ||
        f.region.transform!=='identity' || !unique(f.region.ancestorIds) ||
        !equal(f.region.ancestorIds,first.region.ancestorIds) ||
        f.documentOverflow!==false || !Array.isArray(f.activeNestedRegions) || f.activeNestedRegions.length ||
        !Array.isArray(f.chrome) || !f.chrome.length || f.chrome.some(c=>!id(c?.id)||!box(c.box)) ||
        !unique(f.chrome.map(c=>c.id)) || !equal([...f.chrome.map(c=>c.id)].sort(),[...s.chromeIds].sort()) ||
        f.chrome.some(c=>!inside(c.box,f.viewport)||overlaps(c.box,f.envelope)) || !equal(f.chrome,first.chrome) ||
        f.contentCount!==s.orderedItemKeys.length || f.contentOrderSha256!==s.orderSha256 ||
        !hash(s.orderSha256,64)) return unknown('unstable-or-incomplete-frame');
  }
  // Input provenance must identify each actual dispatched wheel and its pair of snapshots.
  const signs=[1,-1,1,1];
  for (const [i,p] of o.inputs.entries()) {
    if (!p || p.kind!=='wheel' || !finite(p.deltaY) || p.deltaY*signs[i]<=0 ||
        p.regionId!==first.region.id || p.beforeSampleMs!==o.frames[i].sampleMs ||
        p.afterSampleMs!==o.frames[i+1].sampleMs || !id(p.eventId)) return unknown('invalid-input-chain');
  }
  if (!unique(o.inputs.map(p=>p.eventId)) || end.region.top-first.region.top<12 ||
      end.region.top-back.region.top<12 || restored.region.top-back.region.top<12 ||
      !near(end.region.top,restored.region.top) || !near(end.region.top,stable.region.top) ||
      stable.sampleMs-restored.sampleMs<600) return unknown('missing-motion-or-restoration');
  for (const f of [end,back,restored,stable]) {
    const g=f.group;
    if (!g || g.visible!==true || g.unsupportedClip!==false || !Array.isArray(g.ancestorClips) ||
        g.ancestorClips.some(c=>!inside(g.box,c)) || !id(g.id) || g.id!==end.group?.id || g.key!==s.terminalKey || g.index!==s.terminalIndex ||
        g.regionId!==f.region.id || !unique(g.ancestorIds) || !g.ancestorIds.includes(f.region.id) ||
        !equal(g.ancestorIds.slice(g.ancestorIds.indexOf(f.region.id)+1),f.region.ancestorIds) ||
        !equal(g.binding,s.terminalBinding) || !equal(g.ancestorIds,end.group.ancestorIds) || !inside(g.box,g.clip) || !inside(g.box,f.region.box) ||
        !near(g.box.width,r.container.width) || !near(g.box.height,r.container.height) ||
        g.rawInventoryTruncated!==false || g.rawDescendantCount!==g.rawDescendantIds?.length ||
        !Array.isArray(g.parts) || g.parts.length!==s.terminalPartKeys.length ||
        !unique(g.parts.map(p=>p?.key)) || !unique(g.parts.map(p=>p?.id)) ||
        !unique(g.rawDescendantIds) || !equal([...g.rawDescendantIds].sort(),g.parts.map(p=>p.id).sort()) ||
        !s.terminalPartKeys.every(k=>g.parts.some(p=>p.key===k))) return unknown('incomplete-terminal-container');
    for (const p of g.parts) {
      const ref=r.parts.find(x=>x.key===p.key), original=end.group.parts.find(x=>x.key===p.key);
      if (!p || p.visible!==true || p.unsupportedClip!==false || !Array.isArray(p.ancestorClips) ||
          p.ancestorClips.some(c=>!inside(p.box,c)) || !equal(p.binding,s.partBindings[p.key]) || p.id!==original.id || !unique(p.ancestorIds) || p.ancestorIds[0]!==g.id ||
          !equal(p.ancestorIds.slice(1),g.ancestorIds) || !equal(p.ancestorIds,original.ancestorIds) ||
          !inside(p.box,p.clip) || !inside(p.box,g.box) || !near(p.box.width,ref.box.width) ||
          !near(p.box.height,ref.box.height) || !near(p.box.x-g.box.x,ref.box.x-r.container.x) ||
          !near(p.box.y-g.box.y,ref.box.y-r.container.y)) return unknown('incomplete-terminal-part');
    }
    if (!shape(g.box,end.group.box) || !near(g.box.y-end.group.box.y,-(f.region.top-end.region.top)))
      return unknown('terminal-not-moving-with-region');
  }
  const ends=[end,restored,stable];
  if (s.endMode==='dom-extent') {
    if (ends.some(f=>Math.abs(residual(f))>2)) return unknown('dom-end-not-reached');
  } else {
    if (ends.some(f=>!near(f.group.box.y+f.group.box.height+s.trailingPadding,f.region.box.y+f.region.box.height)))
      return unknown('source-tail-not-aligned');
  }
  const proof={kind:s.endMode, referenceSha:s.referenceSha,
    regionId:first.region.id, terminalKey:s.terminalKey, domResiduals:ends.map(residual),
    limitation:'Source-bound terminal reachability only; not all intermediate content or painted text.'};
  if(s.endMode==='source-padding-geometry')return {status:'unverified',reason:'geometric-candidate-awaits-collector-and-extent-validation',proof:null,candidateProof:proof};
  return {status:'proven',reason:null,proof};
}
module.exports={evaluateTerminal};
