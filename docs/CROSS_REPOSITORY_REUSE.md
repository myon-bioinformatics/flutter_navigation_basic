# Cross-repository reuse and import report

> **Status:** Proposed candidates and sequence; no cross-repository runtime dependency is accepted by this document alone.  
> **Decided:** 2026-09, PR #89.  
> **Revisit:** after browser-test-kit reconciliation and the first proven two-repository reuse.

## Goal

`flutter_navigation_basic` should consume useful sibling knowledge and export product-independent contracts only when doing so reduces duplicated maintenance, dependency weight, or inconsistent semantics. “Shared because it might be useful” is not sufficient.

The repository should not become a monorepo/dependency hub. Prefer small contracts, fixtures, scripts, and documentation with pinned provenance.

## Verified sibling snapshot for this report

The following repository descriptions were checked against these `main` SHAs while preparing PR #89; later changes require re-verification:

| Repository | Verified SHA | Relevant surface |
| --- | --- | --- |
| `browser-test-kit` | `7c53a4fcf8761b437e3177e0c12695ba42601698` | browser matrix/evidence/anti-pattern doctrine and executable examples |
| `markdown` | `99b6a174a883f60a9c3ed01164a81fd7bd26ff76` | stdlib transformation + browser-render testing lessons |
| `mcp-toolcall-lab` | `82f40d70ce965d6f1af45b2e96ade3aade9adfa3` | protocol/browser probe and failure-layer lessons |
| `web-ui` | `e7d16a2ce0cee76b7744a4b6a8f8ce374491a4db` | CSS/visual-regression conventions |
| `Ironmate` | `ed5cf73b5b5255d0eecc94cd505b853fad0e8b4e` | repository metadata/index contracts |
| `ascii_artist` | `7c21bacfac7b60327b77f9b31a87869ef7838a7e` | small stdlib conversion patterns |
| `search_seq_including_spaces` | `caa78196d1715c84b524701b8e7f7401c029909c` | parser/fixture/data-processing lessons |

This is provenance for a design report, not a promise that every candidate should be imported.

## Import candidates

| Source | Candidate/use | Coupling rule | Status |
| --- | --- | --- | --- |
| browser-test-kit | browser matrix/evidence metadata/PNG validation/stable browser IDs | Prefer shared vocabulary or a pinned tiny artifact; never depend on sibling `main` at PR runtime | **qualified:** same browser evidence contract already exists here |
| markdown | text/HTML/Markdown helpers, static render lessons | Import only for a concrete feature; no formatting dependency merely for reuse | local/documented until duplicate need appears |
| mcp-toolcall-lab | MCP protocol fixtures, failure-layer taxonomy, browser `fetch` probes | Share protocol contracts, not product UI assumptions | qualified when MCP integration work would otherwise duplicate it |
| web-ui | visual-regression conventions; browser-native stub styling | URL/static boundary; if tokens are shared, limit to small CSS custom-property tokens; Flutter theme remains local | local/documented pending concrete browser-native surface |
| Ironmate | repository metadata/index JSON contracts | Exchange versioned JSON, not application internals | local/documented pending concrete consumer |
| ascii_artist | small conversion patterns | no speculative dependency | local/documented |
| search_seq_including_spaces | generic parser/fixture lessons only | domain logic remains outside this app | local/documented |

## Export candidates and the decision test

A candidate is exportable only when it satisfies at least one decision condition: **D1** two repos already implement the same contract; **D2** another repo is about to duplicate a tested implementation; **D3** shared vocabulary prevents misleading compatibility/evidence claims; **D4** central fixture/schema ownership materially reduces drift.

| Candidate | Condition now | Disposition |
| --- | --- | --- |
| browser evidence vocabulary / mobile claim boundaries | D1 + D3: browser-test-kit and this repo | reconcile with browser-test-kit now; consume its stable IDs |
| Playwright CLI argv regression | D2: browser-test-kit executable-kit goal and tested local incident | propose upstream executable regression; keep local conformance test |
| browser config/install parity guard | D1/D2: both repos protect matrix parity | propose shared contract/example, not a package dependency |
| `outcomes.py` six-state vocabulary | no second active implementation verified yet | **local, documented**; propose schema only when a second consumer appears |
| photo fixture/evidence split | D3 is plausible, no second active media consumer verified | **local, documented** |
| stdlib artifact report | no condition verified | **local, documented** |
| Actions freshness receipt | cross-repo utility is plausible, no second implementation verified in this report | **local, documented** |
| timezone golden/oracle pattern | language-neutral pattern but no second active consumer verified | **local, documented** |
| GetX staged migration lesson | documentation reuse only | keep as architecture lesson, not shared code |
| dependency-audit rubric | documentation reuse only | keep as architecture lesson, not shared code |

This prevents “sharing for sharing's sake,” the cross-repository form of `DEPENDENCY_FOR_CATALOGUE_COMPLETENESS`.

## Reuse mechanisms, lightest first

1. **Documentation / stable IDs.**
2. **Language-neutral JSON fixtures/schemas.**
3. **Single-file stdlib copy with pinned provenance.** Put an upstream header in the copy, for example:
   `# upstream: myon-bioinformatics/browser-test-kit@<sha>:path/to/file.py`
   If drift matters, an **opt-in, non-PR-gating** pytest may fetch that exact upstream SHA and report divergence. Never compare against moving `main`.
4. **Generated/versioned artifact**, pinned to release/SHA and cached.
5. **Package/submodule**, only when independent versioning and direct reuse justify the operational cost.
6. **Sibling network/runtime dependency**, last choice; deterministic local fixtures remain available.

Cross-repo reuse must never mean “curl sibling main during every PR.”

## Shared-contract candidates

### Browser evidence receipt

browser-test-kit is the preferred owner. A portable JSON record can include schema version, repository/commit SHA, runtime, browser engine/project, device/profile + emulation flag, viewport, failure stage, result, screenshot/trace/video paths, optional PNG/dimension validation, and explicit claim level (engine/profile vs physical device).

Flutter Navigation Basic should conform to a versioned contract once one exists rather than fork the vocabulary.

### Test outcome receipt

The local prototype uses:

`passed / failed / skipped / xfailed / xpassed / error`

Keep the implementation local until a second active consumer justifies a shared schema. Flutter reporter parsing remains a Flutter adapter even if the vocabulary becomes shared.

### Fixture + measured evidence split

Photo import separates generator-owned cases/binaries from environment-specific measured evidence. The generator never overwrites measured outcomes, and synthetic evidence cannot upgrade itself into physical-device compatibility. This is a portable lesson; extraction waits for a second consumer.

## What stays local

Product widgets, route tables, screen controllers, platform channels, localization copy, and catalogue examples stay local. Shared code that frequently needs Flutter Navigation Basic product structure is not shared. Likewise, a clear 20-line stdlib implementation can be preferable to a cross-repo dependency.

## Provenance policy

Adapted code/fixtures record source repo/path, exact source commit/release, copied-vs-modified notes, local regression test, and update policy. Documentation lessons record repo@SHA plus stable ID where applicable. This document follows its own policy in the verified snapshot table above.

## Proposed sequence

1. Merge runtime-ownership/browser-matrix policy without adding runtime sibling dependencies.
2. Keep generic browser IDs reconciled to browser-test-kit stable vocabulary.
3. Upstream the exact Playwright argv/parity regression examples where browser-test-kit would otherwise duplicate them.
4. Define/consume a versioned browser evidence JSON contract when browser-test-kit adopts one.
5. Re-evaluate local-only candidates only when a second repository demonstrates an active need.

## Decision test

Export/import only when D1, D2, D3, or D4 is actually evidenced. Otherwise keep the capability **local, documented**.
