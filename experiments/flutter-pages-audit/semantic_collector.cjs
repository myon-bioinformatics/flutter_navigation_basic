'use strict';
// Browser-side read-only discovery collector; never grants acceptance.
// Caller passes a reviewed source inventory, never page-provided selectors/code.
function collectSemanticInventory(spec) {
  const valid = s => s && typeof s.key === 'string' && s.key &&
    ((typeof s.identifier === 'string' && s.identifier && s.label === undefined && s.labelAny === undefined) ||
     (typeof s.label === 'string' && s.label && s.identifier === undefined && s.labelAny === undefined) ||
     (Array.isArray(s.labelAny) && s.labelAny.length>0 && s.labelAny.every(x=>typeof x==='string'&&x) && new Set(s.labelAny).size===s.labelAny.length && s.identifier===undefined && s.label===undefined));
  if (!spec || !Array.isArray(spec.items) || !spec.items.length || !spec.items.every(valid) ||
      new Set(spec.items.map(s=>s.key)).size !== spec.items.length) throw new Error('explicit unique source inventory required');
  const allObserved=[...document.querySelectorAll('flt-semantics')];
  const all=allObserved.slice(0,2000);
  const box=e=>{const b=e.getBoundingClientRect();return{x:b.x,y:b.y,width:b.width,height:b.height};};
  const overlap=(a,b)=>({x:Math.max(a.x,b.x),y:Math.max(a.y,b.y),width:Math.max(0,Math.min(a.x+a.width,b.x+b.width)-Math.max(a.x,b.x)),height:Math.max(0,Math.min(a.y+a.height,b.y+b.height)-Math.max(a.y,b.y))});
  const viewport={x:0,y:0,width:innerWidth,height:innerHeight};
  const ident=e=>e.getAttribute('flt-semantics-identifier')||'';
  const chrome=e=>!!e.closest('[flt-semantics-identifier^="shared-header-"], [flt-semantics-identifier="tool-door-dropdown"]');
  const content=all.filter(e=>!chrome(e));
  const leaves=content.filter(e=>!e.querySelector('flt-semantics'));
  const matches=spec.items.map(s=>({key:s.key,nodes:content.filter(e=>s.identifier?ident(e)===s.identifier:s.labelAny?s.labelAny.includes(e.getAttribute('aria-label')):e.getAttribute('aria-label')===s.label).filter(e=>s.role===undefined||e.getAttribute('role')===s.role)}));
  const selected=matches.flatMap(m=>m.nodes.length===1?m.nodes:[]);
  const common=nodes=>{if(!nodes.length)return null;for(let e=nodes[0];e;e=e.parentElement)if(nodes.every(n=>e.contains(n)))return e;return null;};
  const root=selected.length===spec.items.length?common(selected):null;
  const describe=e=>{
    const ancestorIds=[],ancestorClips=[],ancestorScrollContainers=[];let clip=viewport;let unsupportedClip=false,visible=true;
    for(let p=e;p;p=p.parentElement){const c=getComputedStyle(p);if(c.clipPath&&c.clipPath!=='none')unsupportedClip=true;if(p.getAttribute('aria-hidden')==='true'||c.display==='none'||['hidden','collapse'].includes(c.visibility))visible=false;}
    for(let p=e.parentElement;p;p=p.parentElement){
      if(p.tagName==='FLT-SEMANTICS')ancestorIds.push(p.id||null);const css=getComputedStyle(p);
      if(css.clipPath&&css.clipPath!=='none')unsupportedClip=true;
      if(/(auto|scroll)/.test(`${css.overflowX} ${css.overflowY}`))ancestorScrollContainers.push({id:p.id||null,tag:p.tagName,box:box(p),scrollWidth:p.scrollWidth,clientWidth:p.clientWidth,scrollHeight:p.scrollHeight,clientHeight:p.clientHeight});
      if(/(auto|scroll|hidden|clip)/.test(`${css.overflowX} ${css.overflowY}`)){const b=box(p);ancestorClips.push(b);clip=overlap(clip,b);}
    }
    return{id:e.id||null,identifier:ident(e),role:e.getAttribute('role'),label:e.getAttribute('aria-label'),
      box:box(e),clip,visible,completeSemanticAncestry:true,ancestorIds,ancestorClips,ancestorScrollContainers,unsupportedClip,enabled:e.getAttribute('aria-disabled')!=='true',checked:e.getAttribute('aria-checked'),selected:e.getAttribute('aria-selected'),expanded:e.getAttribute('aria-expanded')};
  };
  const regions=content.filter(e=>{const c=getComputedStyle(e);return['auto','scroll'].includes(c.overflowY)||['auto','scroll'].includes(c.overflowX);}).map(e=>({...describe(e),scrollTop:e.scrollTop,scrollHeight:e.scrollHeight,clientHeight:e.clientHeight,scrollLeft:e.scrollLeft,scrollWidth:e.scrollWidth,clientWidth:e.clientWidth}));
  return {schema:'local-semantic-inventory-prototype/1',sampleMs:performance.now(),rawTruncated:allObserved.length>2000,observedSemanticCount:allObserved.length,viewport,items:matches.map(m=>({key:m.key,count:m.nodes.length,nodes:m.nodes.map(describe)})),
    rawSemanticNodes:content.map(describe),bodyRoot:root?describe(root):null,bodyRootContainsChrome:root?!!root.querySelector('[flt-semantics-identifier^="shared-header-"]'):null,
    annotatedOutsideChromeInventory:content.filter(e=>e.getAttribute('aria-label')||e.getAttribute('role')).map(e=>({id:e.id||null,label:e.getAttribute('aria-label'),role:e.getAttribute('role'),covered:selected.includes(e)})),
    completeOutsideChromeLeafInventory:leaves.map(e=>({id:e.id||null,covered:selected.some(n=>n===e)})),
    scrollRegions:regions,documentOverflow:document.documentElement.scrollWidth>innerWidth||document.documentElement.scrollHeight>innerHeight,
    groups:(spec.groups||[]).map(g=>{const ms=matches.filter(m=>g.keys.includes(m.key));const ok=ms.length===g.keys.length&&ms.every(m=>m.nodes.length===1);const e=ok?common(ms.map(m=>m.nodes[0])):null;return{key:g.key,partKeys:g.keys,container:e?describe(e):null};}),
    limitations:['semantics are not painted glyph bounds','source-key strings are not assumed DOM identifiers','no input or page action performed','no acceptance status inferred by collector']};
}
module.exports={collectSemanticInventory};
