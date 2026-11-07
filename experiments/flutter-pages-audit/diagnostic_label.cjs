'use strict';
// Source-exact Web WeightDiagnosticsStrip label. Caller binds metadata bytes/hash
// to the pinned served revision before use; this file performs no network read.
const ROUTE_SOURCES = Object.freeze({
  '/': 'home_screen', '/hub': 'hub_screen',
  '/examples/counter-playground': 'counter_playground_screen',
  '/examples/irony-generator': 'irony_generator_screen',
  '/examples/composition-generator': 'composition_generator_screen',
  '/examples/ui-showcase': 'ui_showcase_screen',
  '/examples/external-integration/mcp': 'mcp_integration_screen',
});
function bytes(value) {
  if (value === null) return 'not measured';
  if (!Number.isSafeInteger(value) || value < 0) throw new Error('nonnegative safe integer source byte count required');
  const units = ['B', 'KiB', 'MiB', 'GiB'];
  let index = 0;
  while (value >= 1024 && index < units.length - 1) {value /= 1024; index++;}
  // Dart Web toStringAsFixed uses the same Number fixed-point conversion.
  return `${value.toFixed(index ? 2 : 0)} ${units[index]}`;
}
function diagnosticLabel(metadata, route, revision) {
  if (!metadata || !/^\/[A-Za-z0-9/_-]*$/.test(route) || !/^[a-f0-9]{40}$/.test(revision) ||
      metadata.repository?.revision?.sha !== revision || metadata.repository.revision.dirty !== false ||
      typeof metadata.app?.version !== 'string' || !metadata.app.version || /[\r\n]/.test(metadata.app.version) ||
      !metadata.routeSources || typeof metadata.routeSources !== 'object' || Array.isArray(metadata.routeSources)) throw new Error('validated pinned build metadata required');
  const sha = metadata.repository.revision.shortSha;
  if (typeof sha !== 'string' || sha.length < 7 || sha.length > 40 || !revision.startsWith(sha)) throw new Error('consistent displayed short SHA required');
  const repo = bytes(metadata.repository.sourceBytes);
  const sourceId = /^\/screen\d+$/.test(route) ? 'generic_screen' : ROUTE_SOURCES[route];
  const source = sourceId === undefined ? undefined : metadata.routeSources[sourceId];
  if (source !== undefined && (!source || typeof source !== 'object' || !Number.isSafeInteger(source.sourceBytes) || source.sourceBytes < 0)) throw new Error('invalid declared route source');
  const pageLabel = sourceId === 'generic_screen' ? `shared template ${bytes(source?.sourceBytes ?? null)}` :
    source !== undefined ? `page source ${bytes(source.sourceBytes)}` : `repo ${repo}`;
  return `⚖ ${pageLabel} · repo ${repo} · Version v${metadata.app.version} · Commit ${sha}`;
}
module.exports = {diagnosticLabel, formatDiagnosticBytes: bytes, ROUTE_SOURCES};
