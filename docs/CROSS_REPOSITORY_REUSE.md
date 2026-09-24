# Cross-repository reuse and import report

## Goal

`flutter_navigation_basic` should both **consume reusable knowledge/components from sibling repositories** and **export useful, product-independent pieces back out**. Reuse is optional: do it only when it reduces duplicated maintenance, dependency weight, or inconsistent test semantics.

The repository should not become a monorepo or a dependency hub. The preferred model is small contracts, fixtures, scripts, and documentation with explicit provenance.

## Reuse directions

### Import into flutter_navigation_basic

| Source | Candidate | Use here | Coupling rule |
| --- | --- | --- | --- |
| `browser-test-kit` | browser matrix doctrine, evidence metadata, PNG/artifact validation, anti-pattern IDs | Playwright desktop/mobile parity, screenshot/trace evidence, emulation claim boundaries | Prefer copying/adapting a tiny stable script or consuming a versioned artifact later; do not make product CI depend on another repo's main branch |
| `markdown` | stdlib text/HTML/Markdown helpers and browser-render testing lessons | documentation transforms, fixture/report rendering, static HTML probes | Use only if the capability is genuinely needed; avoid pulling a full app dependency for formatting |
| `mcp-toolcall-lab` | MCP protocol fixtures, failure-layer taxonomy, browser `fetch` probes | MCP integration screen/mock server verification | Share protocol fixtures/contracts, not product UI assumptions |
| `web-ui` | common CSS and visual-regression conventions | browser-native stub/demo surfaces | Prefer URL/static asset boundary where practical; Flutter UI should not import CSS merely for visual uniformity |
| `Ironmate` | repository metadata/index contracts | searchable build/repo metadata or Pages integration | Exchange JSON contracts rather than application internals |
| `ascii_artist` | small stdlib conversion patterns | only if an actual text/ASCII feature appears | No speculative dependency |
| `search_seq_including_spaces` | fixture/data-processing patterns | only for generic parser/testing lessons | Domain logic does not belong in this app |

### Export from flutter_navigation_basic

| Candidate | Why portable | Possible destination |
| --- | --- | --- |
| `tool/python/outcomes.py` outcome vocabulary | Normalizes pytest + Flutter-style receipts and rejects corrupt reporter data | browser-test-kit or a small shared CI/testing helper |
| Playwright CLI argv regression | `--project=value` greediness is not Flutter-specific | browser-test-kit anti-pattern + executable example |
| browser config/install parity guard | Generic protection against config/CI/Docker drift | browser-test-kit |
| mobile/browser evidence doctrine | Distinguishes WebKit/iPhone emulation from physical-device proof | browser-test-kit and web-ui |
| photo import fixture/evidence schema | Separates generated cases from measured environment outcomes | browser-test-kit media example or a future media-test kit |
| stdlib artifact report | Generic file-tree size/count/gzip/delta reporting | Ironmate or shared repo-health tooling |
| Actions freshness receipt | Exact-head validation is broadly useful before merge/reuse | shared GitHub/CI tooling |
| timezone fixture/oracle pattern | Language-neutral JSON golden + independent verification | other multi-runtime repos |
| GetX staged migration lessons | General framework-removal strategy: isolate responsibility, don't bulk rewrite | architecture docs/anti-pattern catalogue |
| dependency audit rubric | “representative completeness” prevents dependency growth for demos | other catalogue/reference repos |

## Reuse mechanisms, lightest first

1. **Documentation / stable anti-pattern IDs** — cheapest and often enough.
2. **Language-neutral JSON fixtures/schemas** — good for independent Dart/Python/TS implementations.
3. **Single-file stdlib script copied with provenance** — acceptable when tiny and stable; include upstream path/commit and a parity/update check if drift matters.
4. **Generated artifact consumed at build/test time** — useful for indexes/evidence, pin to a release/SHA and cache it.
5. **Git submodule/package dependency** — use only when independent versioning and direct runtime reuse justify the operational cost.
6. **Network/runtime dependency on sibling repo** — last choice for tests; deterministic local fixtures should remain available.

Cross-repo reuse must not mean “curl sibling main during every PR”. That makes unrelated repository availability part of the product gate.

## Shared-contract candidates

### Browser evidence receipt

A portable JSON record can include:

- schema version;
- repository + commit SHA;
- runtime;
- browser engine/project;
- device/profile and whether it is emulated;
- viewport;
- stage (`install/launch/navigate/interact/assert/screenshot/artifact/cleanup`);
- result;
- screenshot/trace/video paths;
- optional dimensions/PNG validation;
- explicit claim level: engine/profile vs real device.

`browser-test-kit` is the natural owner. Flutter Navigation Basic should consume the contract rather than fork its own vocabulary.

### Test outcome receipt

The existing six-state vocabulary is portable:

`passed / failed / skipped / xfailed / xpassed / error`

A future shared schema could let Dart/Flutter, pytest, Playwright and other repositories emit comparable CI summaries. The current `outcomes.py` is a useful prototype, but extraction should preserve Flutter-specific parsing either as an adapter or in this repository.

### Fixture + measured evidence split

Photo import already demonstrates a strong cross-repo model:

- generator-owned fixture definitions/binaries;
- environment-specific measured evidence stored separately;
- generator never overwrites measured outcomes;
- synthetic evidence never upgrades itself into physical-device compatibility.

This pattern is reusable for browser compatibility, protocol fixtures, media codecs, and external-site probes.

## What should remain local

Do not export product-specific widgets, route tables, screen controllers, platform channel implementations, app localization copy, or catalogue examples merely to increase reuse. Shared code that needs frequent knowledge of Flutter Navigation Basic's product structure is not actually shared.

Similarly, importing another repository is a poor trade if a 20-line stdlib implementation is clearer and more stable locally.

## Provenance policy

When code or fixtures are adapted from a sibling repository, record:

- source repository/path;
- source commit or release;
- what was copied vs modified;
- local regression test;
- update policy.

For documentation-only lessons, a source link/path and stable anti-pattern ID are sufficient.

## Proposed sequence

1. Finish the current runtime-ownership/browser-matrix PR without adding cross-repo runtime dependencies.
2. Compare this repository's anti-pattern IDs with `browser-test-kit`; promote generic browser IDs upstream and keep Flutter-specific IDs local.
3. Propose `outcomes.py`'s schema/vocabulary to browser-test-kit as a cross-runtime receipt, without moving Flutter-specific parser behavior prematurely.
4. Move or mirror the exact Playwright argv and browser parity regressions into browser-test-kit, then keep a small downstream conformance test here.
5. Define a versioned browser evidence JSON schema in browser-test-kit and have this repository emit it.
6. Evaluate generic artifact-report/Actions-freshness helpers for Ironmate or a future small shared tooling package only if at least two repositories actively need the same behavior.
7. Keep product code independent: cross-repo failures should not block the app unless the dependency is intentionally versioned and required.

## Decision test

A cross-repository extraction/import is useful when at least one is true:

- two or more repositories already implement the same contract;
- one repository has a tested implementation and another is about to duplicate it;
- shared vocabulary prevents misleading compatibility/evidence claims;
- centralizing the fixture/schema materially reduces drift.

If none applies, keep it local and document the lesson instead.
