# Observation infrastructure — offline validation only

This change strengthens measurement code without taking new measurements. The
source reference is `c4a7b939e1ad22363321de8b50efe8fcbfb12134` (main after #231),
not a newly observed deployment. Existing screenshots, receipts, failures and
unknown results are not converted or rewritten.

## Status semantics

- **Offline contracts green:** pure predicates, mock-DOM collection, bounded
  driver tests, receipt integrity and historical-reference source hashes pass. It is NOT
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
repository source files at the declared reference;
`proof_contract.py check-historical-source` verifies those exact Git blobs.
Missing reference history or a missing/tampered blob fails without fallback.
`check-current-source` separately compares the working tree with the same recorded
hashes and reports every drift or missing path. The legacy `check-source` command
and receipt aggregation retain this strict current-source behavior.
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
python3 -B -S experiments/flutter-pages-audit/proof_contract.py check-historical-source
# Separate compatibility result; may fail even when historical integrity passes.
python3 -B -S experiments/flutter-pages-audit/proof_contract.py check-current-source
```

No Playwright browser discovery, Flutter execution or screenshot measurement is
part of these commands. The full 430-case configuration is preserved separately
as `full.playwright.config.cjs`, rather than silently running the 48-case grep in
the full lane. HTML comparison remains separate, with unchanged source content
and reference provenance except its explicitly repinned Flutter comparison SHA.

## Historical integrity versus proposed current compatibility

`current-source-projection.v1.json` is a NEW independently versioned source-only
proposal anchored to commit `00eb2c4fc5576489e5a4034736ffcc5502b67671`. It binds the
unchanged historical manifest by SHA256 and retains the historical reference.
It is not a replacement runtime adapter, browser proof, or authorization record.

The 32 source entries retain 30 identical files. The other two decisions are:
- Propose adopting the comment-only workflow filename change in
  `pattern_source_links.dart`. No executable Dart changes are admitted.
- Reject the old workflow path for CURRENT lookup only, preserving its historical
  record. Propose adopting `pages.yml`, workflow display name `Pages`, and both
  gate-name references changing from `Flutter` to `CI`. Exact byte transformations
  are checked; permissions, deployment behavior beyond those name references,
  and all other workflow content must remain identical to the historical source.

`current_source_projection.py` verifies the exact permitted transformations,
complete source coverage, pinned commit hashes and actual working-tree bytes.
It rejects silent reference changes, altered decisions, missing history and
acceptance promotion. The workflow has a separately labeled proposed-current
source compatibility job. Both jobs fetch history; triggers cover all source
paths, including old and new workflow paths. Source drift relative to the OLD
reference still fails `proof_contract.py check-current-source`; this command and
receipt aggregation have not been relaxed or redirected to the proposal.

Acceptance criteria for this LOCAL PROPOSAL are source-only: all 32 historical
hashes remain valid, the two reviewed transformations are exact, all 32 new hashes
match the pinned current commit and working tree, and negative tests reject
unreviewed changes. Publication/adoption has not occurred. No historical JSON,
receipt, screenshot, failed/unknown result, or live-execution setting is changed.
`acceptancePromoted`, `liveExecutionEnabled`, and `archive_ready` remain false;
UI acceptance is unverified. Neither live measurement nor archive retirement is
authorized by this proposal. Historical runtime evidence is never transplanted.

```sh
python3 -B -S experiments/flutter-pages-audit/current_source_projection.py
```
