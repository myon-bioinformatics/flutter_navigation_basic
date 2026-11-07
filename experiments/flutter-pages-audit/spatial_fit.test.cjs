'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {spatialFit} = require('./spatial_fit.cjs');
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
test('complete source-bound spatial proof allows a shared ancestor containing header chrome', () => assert.equal(spatialFit(...fixture()), 'fit_observed'));
test('no historical acceptance flag or fake chrome-free root needed', () => {const f = fixture(); f[1].bodyRootContainsChrome = true; f[2].bodyRootContainsChrome = true; assert.equal(spatialFit(...f), 'fit_observed');});
const failures = {
  noSpec: f => f[0] = null,
  missingSourceHash: f => f[2].sourceHashes = {},
  changedSource: f => f[2].sourceHashes['body.dart'] = 'd'.repeat(64),
  staleBuild: f => f[2].referenceSha = 'e'.repeat(40),
  changedRoute: f => f[2].route = '/screen137',
  changedLocale: f => f[2].locale = 'jpn',
  changedState: f => f[2].stateKey = 'executed',
  rawTruncated: f => f[2].rawTruncated = true,
  noFullTraversal: f => f[2].enumerationComplete = false,
  noNativeTraversal: f => f[2].nativeEnumerationComplete = false,
  omittedRawNode: f => f[2].nodes.pop(),
  duplicateId: f => f[2].nodes[3].id = 'execute',
  unknownLeaf: f => {f[2].nodes.push({...structuredClone(f[2].nodes[1]), id: 'extra', label: ''}); f[2].semanticCount++;},
  unknownText: f => {f[2].nodes.push({...structuredClone(f[2].nodes[1]), id: 'extra', label: 'Unaccounted'}); f[2].semanticCount++;},
  unknownNative: f => {f[2].nodes.push({...structuredClone(f[2].nodes[1]), id: 'input', type: 'native', tag: 'INPUT', label: ''}); f[2].nativeCount++;},
  bodyBehindHeader: f => f[2].nodes[1].box.y = 55,
  bodyBehindFooter: f => f[2].nodes[2].box.y = 460,
  headerDisguisedBody: f => f[2].nodes[3].box.y = 70,
  partialControlClip: f => f[2].nodes[2].clip = {x: 0, y: 76, width: 76, height: 11},
  ancestorPartialClip: f => f[2].nodes[2].ancestorClips = [{x: 0, y: 76, width: 76, height: 11}],
  unsupportedClip: f => f[2].nodes[2].unsupportedClip = true,
  hidden: f => f[2].nodes[1].visible = false,
  nonfinite: f => f[2].nodes[1].box.height = NaN,
  incompleteAncestry: f => f[2].nodes[1].completeAncestry = false,
  missingAncestor: f => f[2].nodes[1].ancestorIds = ['absent'],
  selfAncestor: f => f[2].nodes[1].ancestorIds = ['status', 'root'],
  falseAncestorChain: f => f[2].nodes[1].ancestorIds = ['back', 'root'],
  disabledControl: f => f[2].nodes[2].enabled = false,
  wrongRole: f => f[2].nodes[2].role = 'text',
  wrongLabel: f => f[2].nodes[2].label = '実行 cancel',
  stateRoleSubstitution: f => f[2].nodes[1].role = 'button',
  changedIdentity: f => f[2].nodes[1].id = 'new-status',
  changedGeometry: f => f[2].nodes[1].box.y += 2,
  earlyRestoration: f => f[2].sampleMs = 1599,
  unknownScrollAncestor: f => f[2].nodes[1].scrollAncestorIds = ['unknown'],
  omittedNativeCount: f => delete f[2].nativeCount,
  documentOverflow: f => f[2].document.scrollHeight++,
  nestedOverflow: f => f[2].scrollRegions.push({id: 'nested', scrollWidth: 100, clientWidth: 100, scrollHeight: 200, clientHeight: 100}),
  negativeDocumentExtent: f => f[2].document.scrollHeight = -1,
  missingIntrinsic: f => f[3] = undefined,
  clippedSemanticReference: f => {f[1].nodes[2].box.height = 11; f[2].nodes[2].box.height = 11;},
  wrongReferenceWidth: f => f[3][0].viewport.width = 400,
  referenceAfterRestore: f => f[3][0].sampleMs = 2100,
  wrongReferenceNode: f => f[3][0].nodes[2].id = 'other-control',
  referenceNotFull: f => f[3][0].nodes[2].clip = {x: 0, y: 76, width: 76, height: 11},
  equalReferenceHeights: f => f[0].referenceHeights = [1600, 1600],
  missingReferenceHeight: f => delete f[0].referenceHeights,
  missingSecondReference: f => f[3].pop(),
  malformedSourceMinimum: f => f[0].items[1].minimumSize = {width: 0, height: 32},
  tinyEverywhere: f => {for (const sample of [f[1], f[2], ...f[3]]) sample.nodes[2].box.height = 11;},
  nativeWithoutRoleCannotAvoidIntrinsic: f => {f[0].items[1].selector.type = 'native'; f[0].items[1].selector.tag = 'INPUT'; f[0].items[1].selector.role = null; f[0].items[1].kind = 'content'; delete f[0].items[1].intrinsic; for (const sample of [f[1], f[2]]) {sample.nodes[2].type = 'native'; sample.nodes[2].tag = 'INPUT'; sample.nodes[2].role = null; sample.semanticCount--; sample.nativeCount++;} f[3] = undefined;},
  rolelessSourceControlCannotAvoidIntrinsic: f => {f[0].items[1].selector.role = null; delete f[0].items[1].intrinsic; for (const sample of [f[1], f[2]]) sample.nodes[2].role = null; f[3] = undefined;},
  bodyContainerCannotAvoidIntrinsic: f => {f[0].items[0].kind = 'container';},
  nonbooleanIntrinsic: f => f[0].items[0].intrinsic = 'yes',
  missingClipEnumeration: f => delete f[2].nodes[1].clipEnumerationComplete,
  noAncestorClips: f => f[2].nodes[1].ancestorClips = [],
  identifierOnlyAnnotation: f => {f[0].items[0].area = 'annotation'; f[0].items[0].selector = {type: 'semantic', tag: 'FLT-SEMANTICS', identifier: 'diag', role: 'group'}; for (const sample of [f[1], f[2], ...f[3]]) {sample.nodes[1].role = 'group'; sample.nodes[1].identifier = 'diag';}},
  missingRequiredIntrinsic: f => delete f[0].items[1].intrinsic,
  duplicateSourceKey: f => f[0].items[1].key = 'status',
  wrongSourceAncestor: f => f[0].items[0].ancestorKey = 'back',
  arbitraryStateKey: f => f[0].items[0].state = {covered: true}
};
for (const [name, mutate] of Object.entries(failures)) test(`${name}: remains unverified`, () => {const f = fixture(); mutate(f); assert.equal(spatialFit(...f), 'unverified');});
test('legacy schema is never upgraded into new spatial evidence', () => {const f=fixture();f[1].schema='local-semantic-inventory-prototype/1';assert.equal(spatialFit(...f),'unverified');});

test('undeclared source minimum is not an invented acceptance requirement', () => {const f = fixture(); delete f[0].items[1].minimumSize; assert.equal(spatialFit(...f), 'fit_observed');});
test('without a source minimum, compact clipped dimensions still fail independent full references', () => {const f = fixture(); delete f[0].items[1].minimumSize; f[1].nodes[2].box.height = f[2].nodes[2].box.height = 11; assert.equal(spatialFit(...f), 'unverified');});

test('declared minimum on nonintrinsic content is unsupported rather than ignored', () => {const f = fixture(); f[0].items[0].minimumSize = {width: 900, height: 900}; assert.equal(spatialFit(...f), 'unverified');});
