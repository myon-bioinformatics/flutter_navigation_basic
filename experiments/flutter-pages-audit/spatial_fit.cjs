'use strict';
// Local proof variant only. No browser driver, acceptance import or receipt rewrite.
// spec is a reviewed source inventory; it must never be inferred from observed nodes.
const SHA40 = /^[a-f0-9]{40}$/;
const SHA64 = /^[a-f0-9]{64}$/;
const NONCONTROL_ROLES = new Set([null, 'text', 'heading', 'img', 'paragraph', 'status', 'group']);
const TEXT_TAGS = new Set(['SPAN', 'P', 'DIV', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6']);
const inertTextSpec = item => item.selector.type === 'native' && item.kind === 'content' && TEXT_TAGS.has(item.selector.tag) && item.selector.role === null && nonempty(item.ancestorKey);
const needsIntrinsic = item => item.area === 'body' && (['control', 'container'].includes(item.kind) || item.selector.type === 'native' && !inertTextSpec(item) || !NONCONTROL_ROLES.has(item.selector.role));
const STATE = ['enabled', 'checked', 'selected', 'expanded', 'value'];
const box = value => value && ['x', 'y', 'width', 'height'].every(k => Number.isFinite(value[k])) && value.width > 0 && value.height > 0;
const inside = (item, area) => box(item) && box(area) && item.x >= area.x && item.y >= area.y && item.x + item.width <= area.x + area.width && item.y + item.height <= area.y + area.height;
const equal = (a, b) => box(a) && box(b) && ['x', 'y', 'width', 'height'].every(k => Math.abs(a[k] - b[k]) <= 1);
const unique = values => new Set(values).size === values.length;
const nonempty = value => typeof value === 'string' && value.length > 0;
const hashMap = value => value && typeof value === 'object' && !Array.isArray(value) && Object.keys(value).length > 0 && Object.entries(value).every(([k, v]) => nonempty(k) && SHA64.test(v));
const sameMap = (a, b) => hashMap(a) && hashMap(b) && Object.keys(a).length === Object.keys(b).length && Object.entries(a).every(([k, v]) => b[k] === v);
const axesFit = r => r && [r.scrollWidth, r.clientWidth, r.scrollHeight, r.clientHeight].every(Number.isFinite) && r.clientWidth > 0 && r.clientHeight > 0 && r.scrollWidth >= 0 && r.scrollHeight >= 0 && r.scrollWidth <= r.clientWidth && r.scrollHeight <= r.clientHeight;
const selectorValid = s => s && ['semantic', 'native'].includes(s.type) && nonempty(s.tag) && (nonempty(s.label) || nonempty(s.identifier)) && (s.role === null || typeof s.role === 'string');
function specValid(spec) {
  return spec && nonempty(spec.route) && spec.route.startsWith('/') && SHA40.test(spec.referenceSha) && hashMap(spec.sourceHashes) &&
    nonempty(spec.locale) && nonempty(spec.stateKey) && Array.isArray(spec.items) && spec.items.length > 0 && unique(spec.items.map(x => x?.key)) &&
    spec.items.some(x => x?.area === 'body') && spec.items.some(x => x?.area === 'header') &&
    spec.items.every(x => x && nonempty(x.key) && ['content', 'control', 'container'].includes(x.kind) && selectorValid(x.selector) && ['body', 'header', 'footer', 'annotation'].includes(x.area) &&
      (x.area !== 'annotation' || x.selector.role === 'group' && nonempty(x.selector.label)) &&
      (x.ancestorKey === undefined || nonempty(x.ancestorKey)) && (x.intrinsic === undefined || typeof x.intrinsic === 'boolean') && (x.minimumSize === undefined || x.intrinsic === true) &&
      (x.state === undefined || x.state && typeof x.state === 'object' && !Array.isArray(x.state) && Object.keys(x.state).every(k => STATE.includes(k))) &&
      (!needsIntrinsic(x) || x.intrinsic === true) &&
      (!x.intrinsic || x.area === 'body' && (x.minimumSize === undefined || x.minimumSize && Number.isFinite(x.minimumSize.width) && x.minimumSize.width > 0 && Number.isFinite(x.minimumSize.height) && x.minimumSize.height > 0))) &&
    (!spec.items.some(x => x.intrinsic) || Array.isArray(spec.referenceHeights) && spec.referenceHeights.length === 2 && spec.referenceHeights.every(h => Number.isFinite(h) && h >= 1600) && spec.referenceHeights[1] > spec.referenceHeights[0]);
}
function matches(node, expected) {
  const s = expected.selector;
  return node.type === s.type && node.tag === s.tag && node.role === s.role &&
    (s.label === undefined || node.label === s.label) && (s.identifier === undefined || node.identifier === s.identifier) &&
    Object.entries(expected.state || {}).every(([k, v]) => node[k] === v);
}
function inspect(spec, sample) {
  if (!sample || sample.schema !== 'source-spatial-observation/1' || sample.route !== spec.route || sample.referenceSha !== spec.referenceSha ||
      !sameMap(sample.sourceHashes, spec.sourceHashes) || sample.locale !== spec.locale || sample.stateKey !== spec.stateKey ||
      !Number.isFinite(sample.sampleMs) || !box(sample.viewport) || !inside(sample.envelope, sample.viewport) ||
      !inside(sample.header, sample.viewport) || sample.header.y + sample.header.height > sample.envelope.y ||
      (sample.footer !== null && (!inside(sample.footer, sample.viewport) || sample.footer.y < sample.envelope.y + sample.envelope.height)) ||
      sample.rawTruncated !== false || sample.enumerationComplete !== true || sample.nativeEnumerationComplete !== true ||
      !Array.isArray(sample.nodes) || !sample.nodes.length || !unique(sample.nodes.map(n => n?.id)) ||
      !Number.isInteger(sample.semanticCount) || !Number.isInteger(sample.nativeCount) ||
      sample.semanticCount !== sample.nodes.filter(n => n?.type === 'semantic').length ||
      sample.nativeCount !== sample.nodes.filter(n => n?.type === 'native').length ||
      sample.nodes.length !== sample.semanticCount + sample.nativeCount || !axesFit(sample.document) ||
      !Array.isArray(sample.scrollRegions) || !unique(sample.scrollRegions.map(r => r?.id)) ||
      sample.scrollRegions.some(r => !nonempty(r?.id) || !axesFit(r))) return null;
  const byId = new Map(sample.nodes.map(n => [n?.id, n]));
  for (const n of sample.nodes) {
    if (!n || !nonempty(n.id) || !['semantic', 'native'].includes(n.type) || !nonempty(n.tag) ||
        n.visible !== true || n.unsupportedClip !== false || n.completeAncestry !== true || n.clipEnumerationComplete !== true ||
        !Array.isArray(n.ancestorIds) || !unique(n.ancestorIds) || n.ancestorIds.includes(n.id) ||
        n.ancestorIds.some(id => !nonempty(id) || !byId.has(id)) || !box(n.box) || !inside(n.box, n.clip) ||
        !Array.isArray(n.ancestorClips) || n.ancestorClips.length === 0 || !n.ancestorClips.some(c => ['x', 'y', 'width', 'height'].every(k => c?.[k] === sample.viewport[k])) || n.ancestorClips.some(c => !inside(n.box, c)) ||
        !Array.isArray(n.scrollAncestorIds) || !unique(n.scrollAncestorIds) || n.scrollAncestorIds.some(id => !sample.scrollRegions.some(r => r.id === id))) return null;
    // A complete observed ancestry is a chain, not an arbitrary list of known IDs.
    for (let i = 0; i < n.ancestorIds.length; i++) {
      const ancestor = byId.get(n.ancestorIds[i]);
      if (JSON.stringify(ancestor.ancestorIds) !== JSON.stringify(n.ancestorIds.slice(i + 1))) return null;
    }
  }
  const bound = new Map(), used = new Set();
  for (const expected of spec.items) {
    const candidates = sample.nodes.filter(n => matches(n, expected));
    if (candidates.length !== 1 || used.has(candidates[0].id)) return null;
    const n = candidates[0];
    if (inertTextSpec(expected) && (STATE.some(k => n[k] !== undefined && n[k] !== null) || n.contentEditable !== undefined && n.contentEditable !== null)) return null;
    used.add(n.id); bound.set(expected.key, n);
    const area = expected.area === 'body' ? sample.envelope : expected.area === 'header' ? sample.header : expected.area === 'footer' ? sample.footer : sample.viewport;
    if (!inside(n.box, area)) return null;
    // Label-bearing containers must be source-explicit annotations, never wildcard exclusions.
    if (expected.area === 'annotation' && (n.type !== 'semantic' || n.role !== 'group' || STATE.some(k => n[k] !== undefined && n[k] !== null))) return null;
  }
  for (const expected of spec.items) {
    if (expected.ancestorKey !== undefined && (!bound.has(expected.ancestorKey) || !bound.get(expected.key).ancestorIds.includes(bound.get(expected.ancestorKey).id))) return null;
  }
  // Only genuinely empty structural ancestors can be left unbound. Never hide a leaf,
  // native element, role-bearing control, label, identifier or state behind this rule.
  for (const n of sample.nodes) {
    if (used.has(n.id)) continue;
    if (n.type !== 'semantic' || ![null, 'group'].includes(n.role) || n.label !== '' || n.identifier !== '' ||
        STATE.some(k => n[k] !== undefined && n[k] !== null) || !sample.nodes.some(child => child.ancestorIds.includes(n.id))) return null;
  }
  return bound;
}
function stable(spec, a, b, ba, bb) {
  if (b.sampleMs - a.sampleMs < 600 || !equal(a.viewport, b.viewport) || !equal(a.envelope, b.envelope) || !equal(a.header, b.header) ||
      (a.footer === null ? b.footer !== null : !equal(a.footer, b.footer)) || a.nodes.length !== b.nodes.length) return false;
  for (const n of a.nodes) {
    const m = b.nodes.find(x => x.id === n.id);
    if (!m || n.type !== m.type || n.tag !== m.tag || n.label !== m.label || n.role !== m.role || n.identifier !== m.identifier ||
        STATE.some(k => n[k] !== m[k]) || !equal(n.box, m.box) || !equal(n.clip, m.clip) ||
        JSON.stringify(n.ancestorIds) !== JSON.stringify(m.ancestorIds) || JSON.stringify(n.scrollAncestorIds) !== JSON.stringify(m.scrollAncestorIds)) return false;
  }
  return spec.items.every(item => ba.get(item.key).id === bb.get(item.key).id);
}
function spatialFit(spec, first, restored, intrinsicReference) {
  // No pass on malformed/incomplete records; callers preserve historical outcomes.
  if (!specValid(spec)) return 'unverified';
  const a = inspect(spec, first), b = inspect(spec, restored);
  if (!a || !b || !stable(spec, first, restored, a, b)) return 'unverified';
  const controls = spec.items.filter(x => x.area === 'body' && x.intrinsic === true);
  if (controls.length) {
    if (!Array.isArray(intrinsicReference) || intrinsicReference.length !== 2) return 'unverified';
    const references = intrinsicReference.map(sample => inspect(spec, sample));
    if (references.some(ref => !ref)) return 'unverified';
    for (let index = 0; index < 2; index++) {
      const sample = intrinsicReference[index];
      if (sample.viewport.width !== first.viewport.width || sample.viewport.height !== spec.referenceHeights[index] || sample.viewport.height <= first.viewport.height ||
          sample.sampleMs <= (index ? intrinsicReference[0].sampleMs : first.sampleMs) || sample.sampleMs >= restored.sampleMs) return 'unverified';
    }
    for (const item of controls) {
      const actual = a.get(item.key);
      if (item.minimumSize && (actual.box.width < item.minimumSize.width || actual.box.height < item.minimumSize.height)) return 'unverified';
      for (const ref of references) {
        const full = ref.get(item.key);
        if (actual.id !== full.id || Math.abs(actual.box.width - full.box.width) > 1 || Math.abs(actual.box.height - full.box.height) > 1) return 'unverified';
      }
    }
  }
  return 'fit_observed';
}
module.exports = {spatialFit};
