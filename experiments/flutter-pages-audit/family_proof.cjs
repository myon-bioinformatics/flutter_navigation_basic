'use strict';
// Pure source-to-observation adapter. Unknown inputs never authorize new runs.
const {spatialFit} = require('./spatial_fit.cjs');
const {diagnosticLabel} = require('./diagnostic_label.cjs');
const {createHash} = require('node:crypto');
const {stableCapture} = require('./spatial_signature.cjs');
const {evaluateTerminal} = require('./terminal_proof.cjs');
const clone = value => JSON.parse(JSON.stringify(value));
const unknown = (reason, details = []) => ({status: 'unverified', reason, details, proof: null});
function projectSource(contract, viewport) {
  if (!contract || !Array.isArray(contract.items || contract.groups)) throw new Error('explicit source inventory required');
  if (contract.items) return {items: clone([...contract.items, ...(contract.separateNavigation?.[viewport.width < 900 ? 'compact' : 'wide']?.items || [])]), groups: clone(contract.groups || []), initialState: clone(contract.initialState || {}), terminalGroup: contract.terminalGroup ?? null};
  const items = [], groups = [];
  for (const group of contract.groups) {
    const keys = [];
    for (const part of group.parts) {
      const key = `${group.key}:${part.key}`;
      items.push({...clone(part), key, sourceGroup: group.key}); keys.push(key);
    }
    groups.push({...clone(group), keys});
  }
  if (new Set(items.map(i => i.key)).size !== items.length) throw new Error('duplicate source inventory key');
  return {items, groups, initialState: clone(contract.initialState || {}), terminalGroup: contract.terminalGroup ?? null};
}
function resolveSpatialContract(source, first) {
  let spec = source?.spatial;
  if (!spec || !Array.isArray(spec.items) || !Array.isArray(first?.nodes)) return unknown('source-spatial-binding-not-reviewed', source?.unresolved || []);
  if (spec.route !== source.route || spec.referenceSha !== source.referenceSha || spec.locale !== source.locale || spec.stateKey !== source.stateKey || JSON.stringify(spec.sourceHashes) !== JSON.stringify(source.sourceHashes)) return unknown('source-proof-context-mismatch');
  const resolved = clone(spec);
  if (resolved.dynamicDiagnostic) {
    const metadata = source.buildMetadata;
    if (!metadata || typeof metadata.raw !== 'string' || createHash('sha256').update(metadata.raw).digest('hex') !== metadata.sha256) return unknown('missing-bound-build-metadata');
    let label;
    try {label = diagnosticLabel(JSON.parse(metadata.raw), source.route, source.referenceSha);}
    catch (_) {return unknown('invalid-bound-build-metadata');}
    const item = clone(resolved.dynamicDiagnostic.item);
    item.selectorAlternatives = item.selectorAlternatives.map(selector => ({...selector, label}));
    resolved.items.push(item);
  }
  // DefaultMaterialLocalizations' English BackButton tooltip is an exact source
  // string, not inferred from whatever label happens to be observed.
  // https://api.flutter.dev/flutter/material/DefaultMaterialLocalizations/backButtonTooltip.html
  if (resolved.expectedHeaderTitle && resolved.locale === 'eng') resolved.items.push({key:'chrome:back',kind:'control',area:'header',
    selectorAlternatives:[{type:'semantic',tag:'FLT-SEMANTICS',role:'button',label:'Back'}],
    ancestorKey:'chrome:appbar-title-container',state:{enabled:true},intrinsic:false});
  for (const item of resolved.items) {
    if (!item.selectorAlternatives) continue;
    if (!Array.isArray(item.selectorAlternatives) || !item.selectorAlternatives.length || item.selector) return unknown('invalid-source-alternatives', [item.key]);
    const matches = [];
    for (const selector of item.selectorAlternatives) {
      if (!selector || !['semantic', 'native'].includes(selector.type) || typeof selector.tag !== 'string' || !('role' in selector) || !('label' in selector || 'identifier' in selector)) return unknown('invalid-source-alternatives', [item.key]);
      const nodes = first.nodes.filter(node => node && node.type === selector.type && node.tag === selector.tag && node.role === selector.role &&
        (selector.label === undefined || node.label === selector.label) && (selector.identifier === undefined || node.identifier === selector.identifier));
      if (nodes.length > 1) return unknown('ambiguous-source-binding', [item.key]);
      if (nodes.length === 1) matches.push({selector, nodeId: nodes[0].id});
    }
    if (matches.length !== 1) return unknown(matches.length ? 'ambiguous-source-representation' : 'missing-source-binding', [item.key]);
    item.selector = matches[0].selector;
    delete item.selectorAlternatives;
  }
  // Explicit representation rule for source Text/label descendants. Match the
  // complete source label under its nearest already-bound semantic owner only.
  // This never excludes an unknown leaf or turns an interactive native tag into text.
  const boundNodes = resolved.items.map(item => ({item,node:first.nodes.find(node => node.type===item.selector.type && node.tag===item.selector.tag && node.role===item.selector.role && (item.selector.label===undefined||node.label===item.selector.label) && (item.selector.identifier===undefined||node.identifier===item.selector.identifier))}));
  const boundIds = new Set(boundNodes.map(entry=>entry.node?.id));
  const textTags = ['SPAN','P','DIV','H1','H2','H3','H4','H5','H6'];
  for (const node of first.nodes) {
    if (boundIds.has(node.id) || node.type!=='native' || !textTags.includes(node.tag) || node.role!==null || node.identifier!=='' || !Array.isArray(node.ancestorIds) ||
        ['enabled','checked','selected','expanded','value','contentEditable'].some(key=>node[key]!==undefined&&node[key]!==null)) continue;
    const owners = boundNodes.filter(entry=>entry.node?.type==='semantic' && entry.item.selector.label===node.label && node.ancestorIds.includes(entry.node.id))
      .sort((a,b)=>node.ancestorIds.indexOf(a.node.id)-node.ancestorIds.indexOf(b.node.id));
    if (!owners.length) continue;
    const owner = owners[0];
    const peers = first.nodes.filter(other=>other.type==='native' && other.label===node.label && other.ancestorIds?.includes(owner.node.id) && !boundIds.has(other.id));
    if (peers.length!==1) return unknown('ambiguous-native-text-representation',[owner.item.key]);
    resolved.items.push({key:owner.item.key+':native-text',kind:'content',area:owner.item.area==='annotation'?'footer':owner.item.area,
      selector:{type:'native',tag:node.tag,role:null,label:owner.item.selector.label},ancestorKey:owner.item.key,intrinsic:false});
    boundIds.add(node.id);
  }
  return {status: 'bound', spec: resolved};
}
function evaluateFamilyProof(source, observations) {
  if (!source || !observations || observations.schema !== 'family-proof-observations/1') return unknown('missing-family-proof-observations');
  const frames = observations.spatial?.frames;
  if (Array.isArray(frames) && frames.length === 4) {
    if (observations.spatial.complete !== true || observations.spatial.errors?.length || frames.map(f => f?.phase).join(',') !== 'spatial-initial,spatial-reference-1600,spatial-reference-1720,spatial-restored' || new Set(frames.map(f => f?.capture?.file)).size !== 4 || frames.some(frame => !stableCapture(frame) || !frame.capture || typeof frame.capture.file !== 'string' || !Number.isInteger(frame.capture.bytes) || frame.capture.bytes <= 0 || !/^[a-f0-9]{64}$/.test(frame.capture.sha256 || '') || frame.sample.observedRoute !== source.route)) return unknown('unbound-spatial-capture-or-route');
    const [first, tallA, tallB, restored] = frames;
    const resolution = resolveSpatialContract(source, first.sample);
    if (resolution.status === 'bound') {
      const result = spatialFit(resolution.spec, first.sample, restored.sample, [tallA.sample, tallB.sample]);
      if (result === 'fit_observed') return {status: 'proven', reason: null, proof: {kind: 'source-spatial-fit', scope: 'finite source body fit only', referenceSha: resolution.spec.referenceSha}};
    }
    // A failed fit attempt is not enough to infer that the body must scroll.
    if (!source.terminal) return resolution.status === 'bound' ? unknown('spatial-fit-not-established') : resolution;
  }
  if (source.terminal && observations.terminal) {
    const terminal = evaluateTerminal(source.terminal, observations.terminal);
    // The source-padding mode deliberately remains diagnostic/unverified.
    return terminal;
  }
  return unknown('source-proof-incomplete', source.unresolved || []);
}
module.exports = {projectSource, resolveSpatialContract, evaluateFamilyProof};
