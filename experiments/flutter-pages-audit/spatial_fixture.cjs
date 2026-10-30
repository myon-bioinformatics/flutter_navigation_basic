'use strict';
// Synthetic test fixture only, never a browser observation.
function fixture() {
  const viewport = {x: 0, y: 0, width: 390, height: 500};
  const envelope = {x: 0, y: 56, width: 390, height: 420};
  const spec = {route: '/screen136', referenceSha: 'a'.repeat(40), sourceHashes: {'body.dart': 'b'.repeat(64), 'header.dart': 'c'.repeat(64)}, locale: 'eng', stateKey: 'initial', referenceHeights: [1600, 1720], items: [
    {key: 'status', kind: 'content', area: 'body', selector: {type: 'semantic', tag: 'FLT-SEMANTICS', label: '未実行', role: null}},
    {key: 'execute', kind: 'control', area: 'body', selector: {type: 'semantic', tag: 'FLT-SEMANTICS', label: '実行', role: 'button'}, state: {enabled: true}, intrinsic: true, minimumSize: {width: 48, height: 32}},
    {key: 'back', kind: 'control', area: 'header', selector: {type: 'semantic', tag: 'FLT-SEMANTICS', label: 'Back', role: 'button'}, state: {enabled: true}}
  ]};
  const node = (id, label, role, y, height, parent) => ({id, type: 'semantic', tag: 'FLT-SEMANTICS', label, role, identifier: '', visible: true, unsupportedClip: false,
    completeAncestry: true, clipEnumerationComplete: true, ancestorIds: parent ? [parent] : [], ancestorClips: [viewport], scrollAncestorIds: [], box: {x: 0, y, width: 76, height}, clip: viewport});
  const root = node('root', '', null, 0, 500); root.box.width = 390;
  const status = node('status', '未実行', null, 56, 20, 'root');
  const execute = node('execute', '実行', 'button', 76, 32, 'root'); execute.enabled = true;
  const back = node('back', 'Back', 'button', 8, 40, 'root'); back.enabled = true;
  const first = {schema: 'source-spatial-observation/1', route: spec.route, referenceSha: spec.referenceSha, sourceHashes: spec.sourceHashes, locale: 'eng', stateKey: 'initial',
    sampleMs: 1000, viewport, envelope, header: {x: 0, y: 0, width: 390, height: 56}, footer: null,
    rawTruncated: false, enumerationComplete: true, nativeEnumerationComplete: true, semanticCount: 4, nativeCount: 0,
    nodes: [root, status, execute, back], scrollRegions: [], document: {scrollWidth: 390, clientWidth: 390, scrollHeight: 500, clientHeight: 500}};
  const restored = structuredClone(first); restored.sampleMs = 2000;
  const intrinsic = structuredClone(first); intrinsic.sampleMs = 1400; intrinsic.viewport.height = 1600;
  intrinsic.envelope.height = 1510; intrinsic.document.scrollHeight = intrinsic.document.clientHeight = 1600;
  // root shares the main viewport object in first; reference uses independent boxes below.
  for (const n of intrinsic.nodes) {n.clip = {...intrinsic.viewport}; n.ancestorClips = [{...intrinsic.viewport}];}
  intrinsic.nodes[0].box.height = 1600;
  const second = structuredClone(intrinsic); second.sampleMs = 1700; second.viewport.height = 1720; second.envelope.height = 1630;
  second.document.scrollHeight = second.document.clientHeight = 1720; second.nodes[0].box.height = 1720;
  for (const n of second.nodes) {n.clip = {...second.viewport}; n.ancestorClips = [{...second.viewport}];}
  return [spec, first, restored, [intrinsic, second]];
}
module.exports={fixture};
