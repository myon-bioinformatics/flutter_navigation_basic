'use strict';
// Bounded driver used only by an explicitly selected diagnostic test.
// No retries, reloads, page-specific controls, or implicit viewport expansion.
const {collectSpatialInventory} = require('./spatial_collector.cjs');
const {captureSignature} = require('./spatial_signature.cjs');
async function runSpatialProbe({page, source, viewport, geometry, capture, settle}) {
  if (!source || typeof source.route !== 'string' || !Array.isArray(source.referenceHeights) || source.referenceHeights.length !== 2 ||
      source.referenceHeights[0] !== 1600 || source.referenceHeights[1] !== 1720 || !viewport || ![390, 1180].includes(viewport.width) || ![500, 757].includes(viewport.height)) throw new Error('explicit supported source and viewport budget required');
  const result = {schema: 'spatial-probe/1', scope: 'new diagnostic observations; not historical replay', frames: [], viewportChanges: [], errors: [], budget: {captures: 4, viewportChanges: 3, referenceHeights: [1600, 1720], retries: 0}};
  async function sample(phase) {
    const measured = await geometry(page);
    const context = {route: source.route, referenceSha: source.referenceSha, sourceHashes: source.sourceHashes,
      locale: source.locale, stateKey: source.stateKey, envelope: measured.envelope, header: measured.headerFrame,
      // The measured usable envelope already excludes fixed Door chrome and the
      // source-defined diagnostics strip. This band does not classify its contents:
      // only exact source-bound footer items may use it.
      footer: {x:0, y:measured.envelope.y+measured.envelope.height, width:viewport.width,
        height:(await page.viewportSize()).height-measured.envelope.y-measured.envelope.height}};
    const before = await page.evaluate(collectSpatialInventory, context);
    const screenshot = await capture(phase);
    const after = await page.evaluate(collectSpatialInventory, context);
    result.frames.push({phase, sample: before, afterCapture: after, capture: screenshot, captureStable: captureSignature(before) === captureSignature(after)});
  }
  async function resize(height, phase) {
    await page.setViewportSize({width: viewport.width, height});
    result.viewportChanges.push({width: viewport.width, height, phase});
    await settle(page);
  }
  try {
    await sample('spatial-initial');
    await resize(1600, 'reference-1600'); await sample('spatial-reference-1600');
    await resize(1720, 'reference-1720'); await sample('spatial-reference-1720');
  } catch (error) { result.errors.push({phase: 'probe', message: String(error)}); }
  finally {
    try { await resize(viewport.height, 'restore'); await page.waitForTimeout(600); await sample('spatial-restored'); }
    catch (error) { result.errors.push({phase: 'restore', message: String(error)}); }
  }
  result.complete = !result.errors.length && result.frames.length === 4 && result.viewportChanges.length === 3 && result.frames.every(frame => frame.captureStable);
  return result;
}
module.exports = {runSpatialProbe};
