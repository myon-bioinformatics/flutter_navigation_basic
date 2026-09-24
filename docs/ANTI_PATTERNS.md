# Anti-pattern catalogue

> **Status:** Accepted catalogue; individual entries marked `review-only` are policy/review guards rather than automated gates.  
> **Decided:** 2026-09, PR #89.  
> **Revisit:** after the first runtime-ownership migration slice and browser-test-kit reconciliation.

This catalogue turns failures and migration lessons already present in this repository into reusable review rules. `Scope` distinguishes Flutter-local rules from cross-cutting knowledge. `Guard` distinguishes executable enforcement from review guidance.

For browser-generic concepts, browser-test-kit is the preferred vocabulary owner. This table was reconciled against `myon-bioinformatics/browser-test-kit@7c53a4fcf8761b437e3177e0c12695ba42601698`. Existing upstream IDs are reused exactly where equivalent; remaining `cross-cutting candidate` IDs are provisional until promoted or deliberately kept local.

| ID | Scope | Anti-pattern / failure mode | Preferred pattern | Guard / provenance |
| --- | --- | --- | --- | --- |
| `FRAMEWORK_AS_GOAL` | flutter-local | Preserving Dart/Flutter/GetX because it is already present makes reach and maintenance secondary to framework loyalty | Choose the lightest owner preserving capability and one source of truth | review-only; `GETX_MIGRATION_MAP.md` |
| `BULK_FRAMEWORK_MIGRATION` | flutter-local | Rewriting the historical catalogue in one cleanup creates huge, hard-to-localize risk | Migrate by responsibility and verified batches | review-only; GetX staged migration |
| `GLOBAL_SERVICE_LOCATOR_DEFAULT` | flutter-local (GetX) | Global lookup such as `Get.find` hides coupling and complicates tests | Constructor injection; smallest state primitive | CI keeps handcrafted shell GetX-free + review |
| `DUPLICATE_RUNTIME_SOURCE` | cross-cutting candidate | A production transform is reimplemented as an allegedly independent oracle and silently diverges | One production source; independent oracle/golden only | intentionally review-only until the first Python-oracle candidate exists; see runtime-ownership oracle rule |
| `TOOLING_LANGUAGE_DOGMA` | cross-cutting candidate; tooling specialization of `FRAMEWORK_AS_GOAL` | “Dart by default” or “Python always simpler” forces an unnatural runtime | Boundary-first ownership by total implementation/dependency/ops cost | review-only |
| `PIP_AT_APP_ROOT` | flutter-local | General Python requirements turn dev tooling into an undeclared app runtime | Scoped allowlist; stdlib first | Non-Dart requirements allowlist |
| `SILENT_KNOWN_GAP` | cross-cutting candidate | Removing/omitting a failing case makes CI green by hiding the gap | Keep the case as explicit xfail/known gap | pytest/Flutter outcome receipts; paired with `SKIP_EQUALS_XFAIL` |
| `SKIP_EQUALS_XFAIL` | cross-cutting candidate | Treating every skip as a known failure erases environment-gate semantics | Preserve passed/failed/skipped/xfailed/xpassed/error | `tool/python/outcomes.py`; paired with `SILENT_KNOWN_GAP` |
| `CORRUPT_REPORT_EQUALS_EMPTY_GREEN` | cross-cutting candidate | Malformed reporter output can look like zero failures | Corrupt/non-object records are errors | `tool/python/tests/test_outcomes.py` |
| `FULL_CATALOGUE_EVERYWHERE` | flutter-local | Thousands of reference tests in every compatibility lane make startup dominate signal | Full pinned lane + focused moving/core lanes | CI shard/path design; mobile `@portable` subset |
| `STALE_ACTIONS_GREEN` | cross-cutting candidate | A previous SHA's green run is reused as current proof | Gate receipts against git HEAD | Actions freshness tooling/tests |
| `CLI_ARG_GREEDINESS` | cross-cutting; browser-test-kit stable | Space-separated Playwright `--project chromium <spec>` can consume the spec as another project | Exact argv tests; `--project=chromium` | `test_playwright_cli.py`; upstream stable ID |
| `BROWSER_MATRIX_DRIFT` | cross-cutting; browser-test-kit stable | Config, CI/Docker install and smoke commands disagree | Exact project/install parity regression | `test_playwright_browser_parity.py`; upstream stable ID |
| `ONE_ENGINE_ASSUMPTION` | cross-cutting; browser-test-kit stable | Chromium-only success is called multiplatform | Desktop Chromium/Firefox/WebKit + high-value mobile profiles | Playwright config/parity; upstream stable ID |
| `SAFARI_EQUALS_WEBKIT` | cross-cutting; browser-test-kit stable | Playwright WebKit is reported as branded Safari/device proof | Label WebKit honestly; physical iOS/Safari is separate | docs/evidence review; upstream stable ID |
| `EMULATION_EQUALS_DEVICE` | cross-cutting candidate | Pixel/iPhone descriptors are reported as physical-device proof | Record profile/emulation and retain real-device tail | config comments + evidence review; candidate in upstream doctrine |
| `MOBILE_VIEWPORT_ONLY` | cross-cutting; browser-test-kit stable | Narrow viewport is treated as complete mobile validation | Device-oriented profiles + responsive assertions + real-device OS-boundary tests | mobile Playwright projects; upstream stable ID |
| `SCREENSHOT_AS_SELECTOR` | cross-cutting; browser-test-kit stable | Acting on pixels/screenshots when DOM/locator evidence exists makes automation brittle | Interact through locators/snapshots; use screenshots for visual evidence | upstream `browser-test-kit@7c53a4f`: “Acting on pixels/screenshots when DOM/locator evidence exists”; broader screenshot-as-proof claims remain governed by the evidence rule below |
| `VISUAL_DIFF_TOO_EARLY` | cross-cutting; browser-test-kit stable | Hard visual baselines arrive before deterministic rendering is stable | Stage deterministic smoke/evidence first | visual snapshot lane remains explicit; upstream stable ID |
| `HEAVY_E2E_AS_PR_GATE` | flutter-local | Full Flutter build/browser E2E runs on every unrelated PR | Cheap install/list smoke; explicit heavy lane | Non-Dart workflow; mobile projects restricted to `@portable` |
| `MUTABLE_ASSET_AS_FIXTURE` | flutter-local | Generated build metadata is assumed immutable | Pure parser or dedicated committed fixture | testing rules/review |
| `SYNTHETIC_MEDIA_EQUALS_DEVICE_SUPPORT` | flutter-local, portable lesson | Synthetic HEIC/container evidence is reported as iPhone camera/Safari support | Separate fixture, browser, native-host and physical-device evidence | photo compatibility evidence/tests |
| `DECODE_BEFORE_BUDGET` | cross-cutting candidate | Expensive media decode happens before byte/pixel budgets | Reject before expensive allocation where possible | PhotoImport limits/tests |
| `UI_DIRECT_PLUGIN_COUPLING` | flutter-local | Widgets call picker/native APIs directly | Inject adapter/port boundary | photo media ports/tests |
| `DEPENDENCY_FOR_CATALOGUE_COMPLETENESS` | flutter-local, portable lesson | Package added only to make a reference catalogue look complete | Representative completeness; require real capability | dependency audit/review |
| `COSMETIC_PERMUTATION_GROWTH` | flutter-local | Near-identical screens grow after interaction coverage is complete | Add materially different interaction/accessibility/layout/platform patterns only | UI coverage review |
| `DUAL_ENTRYPOINT_DRIFT` | flutter-local | Pages and production entrypoints/routes diverge | Shared metadata/builders and parity tests | existing entrypoint/route parity tests |
| `PATH_FILTER_BLIND_SPOT` | cross-cutting candidate | CI path filters omit shared config/lock/core inputs | Treat path filters as executable contracts | workflow tests/review |
| `GENERATED_CODE_AS_SOURCE` | cross-cutting candidate | Dart/Markdown/TS generated from JSON is hand-edited or accumulates business logic | JSON/schema is authoritative; generated files are deterministic projections with headers and drift checks | executable photo/time generator `--check` + review |
| `CODEGEN_FOR_ALGORITHM` | cross-cutting candidate | Python/Deno generates arbitrary Dart product algorithms rather than repetitive adapters/data | Generate mechanical data/types/tests/docs only; keep algorithms in their runtime owner | review-only |
| `GOLDEN_WITHOUT_PROVENANCE` | cross-cutting candidate | Expected JSON is copied from the implementation under test and merely freezes its bug | Golden metadata names spec/known-value/provenance; independently derive computational expectations | canonical example: `tool/time/generate_timezone_cases.py` records `Python stdlib zoneinfo / system IANA tzdata`; fixture review/oracle tests |

## Pytest-specific guidance

Pytest is useful here because fixtures, parametrization, xfail, monkeypatching, temporary paths, and small stdlib-oriented tests express tooling contracts with little ceremony. It must not become a second product runtime.

Prefer explicit fixture dependencies, narrowly scoped monkeypatches, and exact observable contracts. Keep `xfail` for known unsupported behavior rather than ordinary skips. A passing xfail (`xpass`) remains visible. For pure argument construction, stub environment setup: the Playwright CLI regression stubs the installed CLI prefix and tests exact argv instead of requiring `node_modules`.

## Browser/media evidence rule

Evidence is a branching structure, not a single ladder:

```text
fixture -> parser/adapter -> Flutter runtime
                         |-> browser engine/profile -> browser on physical device
                         \-> OS/native host --------> installed app on physical device
```

One branch cannot prove the other. Synthetic HEIC, Flutter codec tests, WebKit CI, and iPhone emulation are useful evidence, but none alone proves a real iPhone Photos -> Safari/installed-app flow.

## Adding an incident

For a new portable failure, record ID, affected PR/commit, runtime/browser/profile, observed failure, root cause, fix, regression guard, and portable lesson. Add `Scope` and `Guard` immediately. If browser-test-kit owns an equivalent stable ID, reuse it instead of inventing a Flutter synonym.
