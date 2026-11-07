# Observation infrastructure — offline validation only

This change strengthens measurement code without taking new measurements. The
source reference is `c4a7b939e1ad22363321de8b50efe8fcbfb12134` (main after #231),
not a newly observed deployment. Existing screenshots, receipts, failures and
unknown results are not converted or rewritten.

## Status semantics

- **Offline contracts green:** pure predicates, mock-DOM collection, bounded
  driver tests, receipt integrity and checked-in source hashes pass. It is NOT
  runtime acceptance, full 430-case coverage, or confirmation that a UI bug is fixed.
- **Collection evidence valid:** a saved packet has the exact bounded phases,
  supported census shape, source hashes, ordered before/after snapshots and
  correctly sized/hash-bound PNGs. This still does not establish UI acceptance.
- **Spatial fit proven:** the separate predicate can establish fully contained,
  source-bound content/control bounds only when all its evidence is available.
  It never rewrites the old audit's checks. Painted glyph bounds are not certified.
- **Unverified:** missing binding, incomplete census, engine/native Canvas surface,
  ambiguous group, unsupported clipping, missing intrinsic reference or runtime
  provenance stays unknown, not pass. Source-padding terminal logic remains a
  candidate only; strict DOM residual stays at **2 px**, not widened.

The original two 48-case rounds remain historical and exhausted. In round 2,
48 receipts were structurally valid but 40 required and 96 optional checks were
unknown, with all 48 family bindings unverified. This change reports no new
browser results. Full-audit historical findings remain independent of this CI.

## What is implemented

`source-adapter.json` preserves all 24 source contracts and 48 route/viewport
pairs. Hashes cover 24 original sources plus eight chrome/diagnostic sources.
Source catalog/template projection supplies labels, initial state, groups,
identifiers and source order. Explicit adapters cover source-inferable native /
interactive bodies and header/diagnostic labels. Complex whole-group, native
child, engine and terminal outer-container bindings are not invented.
This checked-in projection records source contracts and hashes of the actual
repository source files; `proof_contract.py check-source` verifies those bytes.
It is not an assertion that 48 runtime adapters are complete.

The collector retains semantic nodes, direct native text (including mixed parent
text), native controls, images/media/Canvas, open shadow roots, ancestors, clips,
scroll regions and document bounds. Unknown leaves cannot disappear to achieve
success. Closed/opaque boundaries and unsupported geometry fail closed.
`family_proof.cjs` preserves source metadata and requires explicit bindings. Native
inert text is accepted only under its exact source-bound semantic owner with
matching text and no control state. No aesthetic/touch-size minimum is invented:
source-declared minima are enforced when present; complete independent same-width
intrinsic bounds can establish size without such an arbitrary minimum.

`spatial_probe.cjs` implements four separate captures per selected case: initial,
1600 px tall, 1720 px tall and restored. There are three viewport transitions,
zero retries and guaranteed restoration attempt. Its hypothetical eight-case
selection is **disabled**, with maximum 32 additional PNGs / 24 transitions
(including 16 tall references). These are additional to legacy audit captures,
not covered by either previous 48-case authorization. No run is requested.
Terminal predicates are integrated as pure functions; unsupported terminal
observation/source binding remains unverified.

## No automatic measurement

Three browser lanes (`flutter-audit-focused-diagnostic.yml`,
`flutter-pages-audit.yml`, `ui-showcase-comparison.yml`) are dispatch-only and
require boolean `run_live_audit: true`; default is false. No pull-request, push or
schedule trigger remains in those lanes. Existing full/focused/comparison failure
semantics remain; an offline green job cannot replace their result.
The new proof selection additionally has `liveExecutionEnabled: false` and
`sourceProofAcceptanceEnabled: false`. Both its config and audit spec reject an
environment-only attempt to enable it. No live CLI is exposed by proof_contract.

`flutter-audit-contracts.yml` runs only stdlib Python and Node test code plus source
hash validation. It has contents-read permission, no browser install/execution,
no credential persistence and a 10-minute bound. The existing general Non-Dart
workflow does not select these experiment/workflow paths; its browser checks
must not be triggered by publishing unrelated product files from a scratch tree.

## Offline commands

```sh
node --test experiments/flutter-pages-audit/*.test.cjs experiments/ui-showcase-html/state.test.cjs
for test_file in experiments/flutter-pages-audit/*.test.py; do python3 -B -S "$test_file"; done
python3 -B -S experiments/flutter-pages-audit/proof_contract.py check-source
```

No Playwright browser discovery, Flutter execution or screenshot measurement is
part of these commands. The full 430-case configuration is preserved separately
as `full.playwright.config.cjs`, rather than silently running the 48-case grep in
the full lane. HTML comparison remains separate, with unchanged source content
and reference provenance except its explicitly repinned Flutter comparison SHA.
