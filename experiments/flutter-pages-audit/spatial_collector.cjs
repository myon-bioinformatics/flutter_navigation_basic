'use strict';
// Browser-evaluable read-only observation, not an acceptance predicate.
// Only the private WeakMap identity registry is persisted. No app attributes change.
function collectSpatialInventory(context) {
  const problems = [];
  const validBox = b => b && ['x','y','width','height'].every(k => Number.isFinite(b[k])) && b.width > 0 && b.height > 0;
  const cloneBox = b => validBox(b) ? {x:b.x,y:b.y,width:b.width,height:b.height} : null;
  const viewport = {x:0,y:0,width:innerWidth,height:innerHeight};
  const input = context && typeof context === 'object' ? context : {};
  const header = cloneBox(input.header), envelope = cloneBox(input.envelope), footer = input.footer === null ? null : cloneBox(input.footer);
  if (!header || !envelope || input.footer !== null && !footer) problems.push('missing driver-measured envelope/chrome geometry');
  const stateSymbol = Symbol.for('flutter-pages-audit.spatial-identities.v1');
  let identity = globalThis[stateSymbol];
  if (!identity || identity.document !== document || !(identity.ids instanceof WeakMap) || !Number.isSafeInteger(identity.next)) {
    identity = {document, ids:new WeakMap(), next:1};
    try {Object.defineProperty(globalThis, stateSymbol, {value:identity, configurable:true});}
    catch (_) {problems.push('stable identity registry unavailable');}
  }
  const id = element => {if (!identity.ids.has(element)) identity.ids.set(element, `spatial-node-${identity.next++}`); return identity.ids.get(element);};
  const elements = [], seen = new Set(), opaque = [], traversalErrors = [];
  const maxElements = 20000, maxNodes = 4000;
  const knownFlutterHosts = new Set(['FLUTTER-VIEW','FLT-SEMANTICS','FLT-SEMANTICS-CONTAINER','FLT-SEMANTICS-PLACEHOLDER','FLT-SEMANTICS-HOST',
    'FLT-TEXT-EDITING-HOST','FLT-TEXT-EDITING-PROXY','FLT-TEXT-FIELD','FLT-GLASS-PANE','FLT-SCENE-HOST','FLT-SCENE','FLT-CANVAS',
    'FLT-PLATFORM-VIEW','FLT-PLATFORM-VIEW-SLOT','FLT-IMAGE','FLT-PARAGRAPH']);
  let truncated = false;
  const childrenOf = element => Array.from(element.children || []);
  const walk = root => {
    for (const element of childrenOf(root)) {
      if (seen.has(element)) continue;
      if (elements.length >= maxElements) {truncated = true; return;}
      seen.add(element); elements.push(element);
      const tag = element.tagName || '';
      if (['IFRAME','OBJECT','EMBED'].includes(tag)) opaque.push({id:id(element),tag,reason:'embedded document not enumerated'});
      try {
        // Unknown custom elements can hide closed author shadow content. Known Flutter
        // hosts are source/runtime reviewed; this does not inspect UA control internals.
        if (tag.includes('-') && !knownFlutterHosts.has(tag) && !element.shadowRoot) {
          opaque.push({id:id(element),tag,reason:'custom element has no inspectable author shadow root'});
        }
        if (element.shadowRoot) walk(element.shadowRoot);
        walk(element);
      } catch (error) {traversalErrors.push(String(error));}
    }
  };
  try {walk(document);} catch (error) {traversalErrors.push(String(error));}
  if (traversalErrors.length) problems.push('DOM traversal incomplete');
  if (opaque.length) problems.push('opaque DOM boundary');
  const attribute = (e,k) => e.getAttribute(k);
  const parent = e => e.parentElement || e.getRootNode?.().host || null;
  const chain = e => {
    const result = [], visited = new Set([e]);
    for (let p=parent(e); p; p=parent(p)) {
      if (visited.has(p)) {problems.push('cyclic composed ancestry'); break;}
      visited.add(p);result.push(p);
    }
    return result;
  };
  const ownText = element => Array.from(element.childNodes || []).map(n => {
    if (n.nodeType === 3) return n.textContent || '';
    if (n.nodeType === 1 && n.tagName !== 'FLT-SEMANTICS' && !['SCRIPT','STYLE','NOSCRIPT','TEMPLATE'].includes(n.tagName)) return ownText(n);
    return '';
  }).join('').trim();
  const directText = e => Array.from(e.childNodes || []).filter(n=>n.nodeType===3).map(n=>n.textContent||'').join('').trim();
  const replacedContent = e => ['IMG','IMAGE','SVG','VIDEO','AUDIO','CANVAS','PICTURE','OBJECT','EMBED','IFRAME','HR','METER','PROGRESS'].includes(String(e.tagName).toUpperCase());
  const excludedTag = e => ['SCRIPT','STYLE','NOSCRIPT','TEMPLATE','HEAD','TITLE','META','LINK'].includes(e.tagName);
  const semantic = e => e.tagName === 'FLT-SEMANTICS';
  const nativeControl = e => ['INPUT','TEXTAREA','SELECT','BUTTON','OPTION','SUMMARY'].includes(e.tagName) || e.tagName==='A'&&attribute(e,'href')!==null || attribute(e,'contenteditable') === '' || attribute(e,'contenteditable') === 'true';
  const nativeContent = e => {
    if (excludedTag(e) || e.tagName.startsWith('FLT-') || e.tagName === 'FLUTTER-VIEW') return false;
    if (nativeControl(e) || replacedContent(e)) return true;
    if (attribute(e,'role') !== null || attribute(e,'aria-label') !== null || attribute(e,'flt-semantics-identifier') !== null) return true;
    // A wrapper with direct text is content even when another child has its own
    // text. Retain both: dropping the wrapper would hide its unmatched direct text.
    // Empty wrappers containing only accounted descendant text are not duplicated.
    return directText(e) !== '' || ownText(e) !== '' && !childrenOf(e).some(c => !excludedTag(c) && (semantic(c) || ownText(c) !== ''));
  };
  const candidates = elements.filter(e => semantic(e) || nativeContent(e));
  if (candidates.length > maxNodes) truncated = true;
  const selected = candidates.slice(0,maxNodes), selectedSet = new Set(selected);
  const ancestryByElement=new Map(selected.map(e=>[e,chain(e)]));
  const descendantsByElement=new Map(selected.map(e=>[e,[]]));
  for (const e of selected) for (const ancestor of ancestryByElement.get(e)) if (descendantsByElement.has(ancestor)) descendantsByElement.get(ancestor).push(id(e));
  const style = e => {try {return getComputedStyle(e);} catch (_) {problems.push('computed style unavailable'); return null;}};
  const rect = e => {try {const b=e.getBoundingClientRect();return {x:b.x,y:b.y,width:b.width,height:b.height};} catch (_) {problems.push('bounding box unavailable');return null;}};
  const clips = value => ['auto','scroll','hidden','clip'].includes(value);
  const scrolling = value => ['auto','scroll'].includes(value);
  const supportedTransform = css => {
    const transform = css?.transform;
    if (!transform || transform === 'none') return true;
    const m = /^matrix\(([^)]+)\)$/.exec(transform);
    if (!m) return false;
    const numbers=m[1].split(',').map(Number);
    return numbers.length===6 && numbers.every(Number.isFinite) && numbers[0]>0 && numbers[3]>0 && numbers[1]===0 && numbers[2]===0;
  };
  const clientBox = e => {
    const b=rect(e);if(!b)return null;
    const ow=Number(e.offsetWidth),oh=Number(e.offsetHeight),cw=Number(e.clientWidth),ch=Number(e.clientHeight),left=Number(e.clientLeft),top=Number(e.clientTop);
    if (![ow,oh,cw,ch,left,top].every(Number.isFinite) || ow<=0 || oh<=0 || cw<0 || ch<0) return null;
    return {x:b.x+left*b.width/ow,y:b.y+top*b.height/oh,width:cw*b.width/ow,height:ch*b.height/oh};
  };
  const regionElements = elements.filter(e => {const css=style(e);return css && (scrolling(css.overflowX)||scrolling(css.overflowY));});
  const regionSet = new Set(regionElements);
  const region = e => ({id:id(e),domId:e.id||'',tag:e.tagName,box:clientBox(e),transform:style(e)?.transform??null,overflowX:style(e)?.overflowX??null,overflowY:style(e)?.overflowY??null,
    scrollWidth:e.scrollWidth,clientWidth:e.clientWidth,scrollHeight:e.scrollHeight,clientHeight:e.clientHeight,
    scrollLeft:e.scrollLeft,scrollTop:e.scrollTop,ancestorIds:chain(e).filter(p=>selectedSet.has(p)).map(id)});
  const intersect = (a,b) => ({x:Math.max(a.x,b.x),y:Math.max(a.y,b.y),width:Math.max(0,Math.min(a.x+a.width,b.x+b.width)-Math.max(a.x,b.x)),height:Math.max(0,Math.min(a.y+a.height,b.y+b.height)-Math.max(a.y,b.y))});
  const describe = e => {
    const ancestors=ancestryByElement.get(e)||chain(e), nodes=[e,...ancestors], ancestorClips=[{...viewport}];
    let clip={...viewport},visible=true,unsupportedClip=false,clipEnumerationComplete=true;
    for (const p of nodes) {
      const css=style(p);
      if (!css) {visible=false;clipEnumerationComplete=false;continue;}
      if (attribute(p,'aria-hidden')==='true' || css.display==='none' || ['hidden','collapse'].includes(css.visibility) || Number(css.opacity)===0 || attribute(p,'hidden')!==null) visible=false;
      if (css.clipPath && css.clipPath!=='none' || css.maskImage && css.maskImage!=='none' || !supportedTransform(css) || css.clip && css.clip!=='auto' || (clips(css.overflowX)||clips(css.overflowY)) && [css.borderTopLeftRadius,css.borderTopRightRadius,css.borderBottomLeftRadius,css.borderBottomRightRadius].some(r=>r&&r!=='0px'&&r!=='0px 0px')) unsupportedClip=true;
      if (p !== e && (clips(css.overflowX)||clips(css.overflowY))) {
        const b=clientBox(p);
        if (!b) {clipEnumerationComplete=false;unsupportedClip=true;continue;}
        const c={x:clips(css.overflowX)?b.x:viewport.x,y:clips(css.overflowY)?b.y:viewport.y,width:clips(css.overflowX)?b.width:viewport.width,height:clips(css.overflowY)?b.height:viewport.height};
        ancestorClips.push(c);clip=intersect(clip,c);
      }
    }
    const role=attribute(e,'role'),ariaLabel=attribute(e,'aria-label'),text=ownText(e);
    const result={id:id(e),domId:e.id||'',type:semantic(e)?'semantic':'native',tag:e.tagName,
      identifier:attribute(e,'flt-semantics-identifier')||'',role,label:ariaLabel===null?text:ariaLabel,ariaLabel,text,directText:directText(e),replacedContent:replacedContent(e),
      box:rect(e),clip,visible,unsupportedClip,clipEnumerationComplete,
      completeAncestry:traversalErrors.length===0&&!truncated,ancestorIds:ancestors.filter(p=>selectedSet.has(p)).map(id),ancestorClips,
      scrollAncestorIds:ancestors.filter(p=>regionSet.has(p)).map(id),
      rawDescendantIds:descendantsByElement.get(e)||[],
      descendantEnumerationComplete:traversalErrors.length===0&&!truncated&&!opaque.length};
    const interactiveRoles=['button','checkbox','textbox','switch','tab','combobox','slider','listbox','radio','menuitem','spinbutton'];
    if (nativeControl(e)||interactiveRoles.includes(role)) {
      let disabled=e.disabled===true||attribute(e,'aria-disabled')==='true';
      try {if (typeof e.matches==='function' && e.matches(':disabled')) disabled=true;} catch (_) {problems.push('native disabled state unavailable');}
      result.enabled=!disabled;
    }
    for (const name of ['checked','selected','expanded']) {
      const value=attribute(e,'aria-'+name);
      if (value !== null) result[name]=value==='true'?true:value==='false'?false:value;
      else if (name==='checked'&&e.tagName==='INPUT'&&['checkbox','radio'].includes(e.type)) result.checked=Boolean(e.checked);
      else if (name==='selected'&&e.tagName==='OPTION') result.selected=Boolean(e.selected);
    }
    if (['INPUT','TEXTAREA','SELECT'].includes(e.tagName)) {result.value=e.tagName==='INPUT'&&['password','hidden'].includes(e.type)?null:typeof e.value==='string'?e.value:null;result.inputType=e.type||null;if(e.tagName==='INPUT'&&['password','hidden'].includes(e.type))result.valueRedacted=true;result.readOnly=e.readOnly===true;}
    if (attribute(e,'contenteditable')!==null) {result.contentEditable=attribute(e,'contenteditable');result.value=text;}
    return result;
  };
  const observedNodes=selected.map(describe),documentRoot=document.documentElement;
  const scrollRegions=regionElements.map(region);
  const locationRecord={pathname:globalThis.location?.pathname??null,hash:globalThis.location?.hash??null,search:globalThis.location?.search??null};
  const observedRoute=typeof locationRecord.hash==='string'&&locationRecord.hash.startsWith('#/')?locationRecord.hash.slice(1).split('?')[0]:locationRecord.pathname;
  let active=document.activeElement||null;
  while(active?.shadowRoot?.activeElement) active=active.shadowRoot.activeElement;
  const rootStyle=style(documentRoot);
  const displayObservation={documentLang:documentRoot.lang||attribute(documentRoot,'lang')||'',visibilityState:document.visibilityState??null,
    devicePixelRatio:globalThis.devicePixelRatio??null,visualViewportScale:globalThis.visualViewport?.scale??null,
    cssRootFontSize:rootStyle?.fontSize??null,cssColorScheme:rootStyle?.colorScheme??null,fontLoadingStatus:document.fonts?.status??null,
    activeElement:active?{id:id(active),domId:active.id||'',tag:active.tagName,role:attribute(active,'role')}:null,
    flutterTextScaleObserved:false,flutterThemeObserved:false};
  const complete=!truncated&&!traversalErrors.length&&!opaque.length&&!problems.length;
  return {schema:'source-spatial-observation/1',contextOrigin:'driver-verified-context-not-independent-proof',
    route:input.route,referenceSha:input.referenceSha,sourceHashes:input.sourceHashes,locale:input.locale,stateKey:input.stateKey,
    observedRoute,location:locationRecord,displayObservation,sampleMs:performance.now(),viewport,envelope,header,footer,nodes:observedNodes,
    semanticCount:observedNodes.filter(n=>n.type==='semantic').length,nativeCount:observedNodes.filter(n=>n.type==='native').length,
    observedElementCount:elements.length,observedCandidateCount:candidates.length,rawTruncated:truncated,
    enumerationComplete:complete,nativeEnumerationComplete:complete,scrollRegions,
    document:{scrollWidth:documentRoot.scrollWidth,clientWidth:documentRoot.clientWidth,scrollHeight:documentRoot.scrollHeight,clientHeight:documentRoot.clientHeight},
    opaqueBoundaries:opaque,problems:[...new Set(problems)],traversalErrors,
    limitations:['Accessible author DOM and open shadow roots only; closed roots are not retroactively inspectable.',
      'Known Flutter hosts require separately pinned source/runtime provenance.',
      'Context identity and chrome geometry are supplied by the driver, not independently verified by this collector.',
      'Semantics do not certify painted glyph bounds; no acceptance outcome is assigned.']};
}
module.exports={collectSpatialInventory};
