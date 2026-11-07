'use strict';
function captureSignature(sample) {
  if (!sample || typeof sample !== 'object') return null;
  return JSON.stringify({viewport: sample.viewport, envelope: sample.envelope, header: sample.header, footer: sample.footer,
    observedRoute: sample.observedRoute, referenceSha: sample.referenceSha, sourceHashes: sample.sourceHashes, locale: sample.locale, stateKey: sample.stateKey,
    nodes: sample.nodes, scrollRegions: sample.scrollRegions, document: sample.document, rawTruncated: sample.rawTruncated,
    enumerationComplete: sample.enumerationComplete, nativeEnumerationComplete: sample.nativeEnumerationComplete});
}
function stableCapture(frame) {
  return frame && frame.captureStable === true && Number.isFinite(frame.sample?.sampleMs) && Number.isFinite(frame.afterCapture?.sampleMs) &&
    frame.afterCapture.sampleMs >= frame.sample.sampleMs && captureSignature(frame.sample) === captureSignature(frame.afterCapture);
}
module.exports = {captureSignature, stableCapture};
