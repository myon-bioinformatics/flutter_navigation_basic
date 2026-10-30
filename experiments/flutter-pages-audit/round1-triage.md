# PR #230 round 1 evidence triage (2026-10-30)

Run: https://github.com/myon-bioinformatics/flutter_navigation_basic/actions/runs/41017079273

Artifact: `12960765005` (`flutter-audit-family-discovery-d65322c1`). Candidate `3a194317a7d8bea0cebb6299cb35cc215db30431`; served baseline `d65322c15a55a7395bb5271bc65696402bc98d29`.

Offline replay validates all 48 receipts and screenshot hashes, source manifest and timestamps: collectionEvidenceValid=true, requiredFailed=0, requiredUnverified=40, optionalUnverified=96, familyBindingUnverifiedPairs=48, acceptancePromoted=false. Expected aggregate exit code is 1. No new browser measurement is represented by replay.

## Classification

- All 40 required unknowns belong to scroll. 33 lack identified region/positive complete-fit proof; seven moved but did not prove an endpoint. These categories describe evidence gaps, not 40 confirmed application defects.
- Seven endpoint gaps: Hub compact/wide 3/8px, Screen3 compact 5px, Screen5 compact/wide 18/18px, Screen103 and Screen91 compact 59px each. All have moved=true and boundaryObserved=false. Stop/no-op and visible last text do not prove endpoint. Do not enlarge the tolerance.
- Confirmed observer defect: collector matched aria-label only, while initial.leaves/inventory retain textContent labels for the same semantic IDs. E.g. Screen165 wide metadata and Simulate async task are visible/inventoried but absent from collector matches. Added exact own-DOM-text fallback and raw text/matchedLabel; aria-label takes precedence and semantic descendants cannot impersonate parents. This is discovery-only and does not repair or promote scroll checks.
- Undefined contracts: source parts can merge into one semantic checkbox (e.g. N and Navigation: ModalBottomSheet); source inventories enumerate virtualized Hub/Screen6 items not simultaneously present in DOM. All 48 stable snapshots have missing source matches and no bound bodyRoot. Text fallback alone cannot resolve those contracts. A complete body and source terminal-card binding still require fresh evidence.
- Confirmed visual application finding: Screen100 compact tabs occupy y325–405, while usable body ends at y346. Only 21px of the 80px tab box are usable; initial and post-wheel geometry remain the same, and final.png shows tab labels hidden behind the footer. Existing limited body_geometry passing does not certify complete control visibility. No production Dart change is included.
- Additional application candidates: Screen39/129/165 and other compact generic templates lose primary controls from exposed semantics while metadata/chips fill the body. Source short-height wrapper is Screen6-specific. Do not claim these controls are functionally inoperable without dedicated interaction/visibility contracts.
- No additional legitimate not_applicable was established. Finite-looking screenshots alone do not prove complete containment. Intentional absent footers are separate from scroll applicability.
- Optional page_action and painted_text_overflow remain unverified in all 48 pairs (96 checks). They need dedicated safe-action/paint contracts and are not made not_applicable merely to complete the audit.

## Verification and independent review

40 Node tests passed (25 policy + 15 collector, including four new DOM-text regressions); 30 Python tests passed (audit13/family9/workflow3/focused5). JS syntax and git diff --check passed. Independent reviewer separately ran collector15, inspected all 48 final screenshots and cross-checked the seven endpoint receipts and source structures. No blocking issue in the narrow collector change. Existing scroll/acceptance logic, source manifest, baseline and workflows are unchanged.

Round 2 is allowed only as the second and final 48-pair discovery measurement: same 24 routes, 2 viewports, 2 workers, retries=0, timeout=90s/case, 45min/job, seven-day artifacts, fixed baseline and all 24 source hashes checked before/after. Exact existing title transition must name the final candidate SHA. Push/body edits alone do not authorize extra measurements. Round 2 is to measure corrected bindings, not assert that scroll unknowns have been solved.

## Integration gate

Do not integrate into #223 until all required representative contracts are verified and independently reviewed. In particular the collector is not an acceptance oracle. Keep #230 and #223 Draft and preserve prior raw results. No full430 run or comparison run is requested by this triage.

## Pair ledger

Receipt paths are relative to the retained artifact. No historical status is rewritten.

| Route | Viewport | Scroll | Evidence gap | Receipt |
|---|---|---|---|---|
| `/examples/external-integration/mcp` | compact-390x500 | passed | none (limited scroll check passed) | `cases/audit-observe-public-route-examples-external-integration-mcp-compact-390x500/audit-receipt.json` |
| `/examples/external-integration/mcp` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-examples-external-integration-mcp-wide-1180x757/audit-receipt.json` |
| `/examples/irony-generator` | compact-390x500 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-examples-irony-generator-compact-390x500/audit-receipt.json` |
| `/examples/irony-generator` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-examples-irony-generator-wide-1180x757/audit-receipt.json` |
| `/examples/ui-showcase` | compact-390x500 | passed | none (limited scroll check passed) | `cases/audit-observe-public-route-examples-ui-showcase-compact-390x500/audit-receipt.json` |
| `/examples/ui-showcase` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-examples-ui-showcase-wide-1180x757/audit-receipt.json` |
| `/hub` | compact-390x500 | unverified | moved; endpoint unproven | `cases/audit-observe-public-route-hub-compact-390x500/audit-receipt.json` |
| `/hub` | wide-1180x757 | unverified | moved; endpoint unproven | `cases/audit-observe-public-route-hub-wide-1180x757/audit-receipt.json` |
| `/screen100` | compact-390x500 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen100-compact-390x500/audit-receipt.json` |
| `/screen100` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen100-wide-1180x757/audit-receipt.json` |
| `/screen103` | compact-390x500 | unverified | moved; endpoint unproven | `cases/audit-observe-public-route-screen103-compact-390x500/audit-receipt.json` |
| `/screen103` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen103-wide-1180x757/audit-receipt.json` |
| `/screen111` | compact-390x500 | passed | none (limited scroll check passed) | `cases/audit-observe-public-route-screen111-compact-390x500/audit-receipt.json` |
| `/screen111` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen111-wide-1180x757/audit-receipt.json` |
| `/screen129` | compact-390x500 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen129-compact-390x500/audit-receipt.json` |
| `/screen129` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen129-wide-1180x757/audit-receipt.json` |
| `/screen136` | compact-390x500 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen136-compact-390x500/audit-receipt.json` |
| `/screen136` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen136-wide-1180x757/audit-receipt.json` |
| `/screen147` | compact-390x500 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen147-compact-390x500/audit-receipt.json` |
| `/screen147` | wide-1180x757 | passed | none (limited scroll check passed) | `cases/audit-observe-public-route-screen147-wide-1180x757/audit-receipt.json` |
| `/screen165` | compact-390x500 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen165-compact-390x500/audit-receipt.json` |
| `/screen165` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen165-wide-1180x757/audit-receipt.json` |
| `/screen171` | compact-390x500 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen171-compact-390x500/audit-receipt.json` |
| `/screen171` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen171-wide-1180x757/audit-receipt.json` |
| `/screen173` | compact-390x500 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen173-compact-390x500/audit-receipt.json` |
| `/screen173` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen173-wide-1180x757/audit-receipt.json` |
| `/screen174` | compact-390x500 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen174-compact-390x500/audit-receipt.json` |
| `/screen174` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen174-wide-1180x757/audit-receipt.json` |
| `/screen183` | compact-390x500 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen183-compact-390x500/audit-receipt.json` |
| `/screen183` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen183-wide-1180x757/audit-receipt.json` |
| `/screen185` | compact-390x500 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen185-compact-390x500/audit-receipt.json` |
| `/screen185` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen185-wide-1180x757/audit-receipt.json` |
| `/screen21` | compact-390x500 | passed | none (limited scroll check passed) | `cases/audit-observe-public-route-screen21-compact-390x500/audit-receipt.json` |
| `/screen21` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen21-wide-1180x757/audit-receipt.json` |
| `/screen3` | compact-390x500 | unverified | moved; endpoint unproven | `cases/audit-observe-public-route-screen3-compact-390x500/audit-receipt.json` |
| `/screen3` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen3-wide-1180x757/audit-receipt.json` |
| `/screen39` | compact-390x500 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen39-compact-390x500/audit-receipt.json` |
| `/screen39` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen39-wide-1180x757/audit-receipt.json` |
| `/screen5` | compact-390x500 | unverified | moved; endpoint unproven | `cases/audit-observe-public-route-screen5-compact-390x500/audit-receipt.json` |
| `/screen5` | wide-1180x757 | unverified | moved; endpoint unproven | `cases/audit-observe-public-route-screen5-wide-1180x757/audit-receipt.json` |
| `/screen57` | compact-390x500 | passed | none (limited scroll check passed) | `cases/audit-observe-public-route-screen57-compact-390x500/audit-receipt.json` |
| `/screen57` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen57-wide-1180x757/audit-receipt.json` |
| `/screen6` | compact-390x500 | passed | none (limited scroll check passed) | `cases/audit-observe-public-route-screen6-compact-390x500/audit-receipt.json` |
| `/screen6` | wide-1180x757 | passed | none (limited scroll check passed) | `cases/audit-observe-public-route-screen6-wide-1180x757/audit-receipt.json` |
| `/screen75` | compact-390x500 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen75-compact-390x500/audit-receipt.json` |
| `/screen75` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen75-wide-1180x757/audit-receipt.json` |
| `/screen91` | compact-390x500 | unverified | moved; endpoint unproven | `cases/audit-observe-public-route-screen91-compact-390x500/audit-receipt.json` |
| `/screen91` | wide-1180x757 | unverified | no complete region/fit proof | `cases/audit-observe-public-route-screen91-wide-1180x757/audit-receipt.json` |
