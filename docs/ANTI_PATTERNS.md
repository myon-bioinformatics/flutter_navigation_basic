# Anti-pattern catalogue

This catalogue turns failures and migration lessons already present in this repository into reusable review rules. It covers Flutter/Dart, pytest/Python, Playwright/browser testing, CI, media/platform boundaries, and dependency/runtime ownership.

The IDs are intentionally stable enough to reference from reviews and regression tests. Add a new ID only when the failure mode is portable beyond one line of code.

| ID | Anti-pattern | Failure mode | Preferred pattern |
| --- | --- | --- | --- |
| `FRAMEWORK_AS_GOAL` | Preserving Dart/Flutter/GetX because it is already present | Platform reach and maintenance cost become secondary to framework loyalty | Choose the lightest owner that preserves the capability and one source of truth |
| `BULK_FRAMEWORK_MIGRATION` | Rewriting the historical catalogue in one cleanup | Huge review surface, educational examples lose meaning, regressions are hard to localize | Migrate by responsibility and verified batches; isolate intentionally framework-specific examples |
| `GLOBAL_SERVICE_LOCATOR_DEFAULT` | New code reaches through global lookup for dependencies | Hidden coupling and difficult tests | Constructor injection; smallest state primitive that fits |
| `DUPLICATE_RUNTIME_SOURCE` | Reimplementing a production formula/transform in Python or JS without a clear oracle boundary | Two implementations silently diverge | One production source of truth; reference oracle only when independently useful and explicitly tested |
| `TOOLING_LANGUAGE_DOGMA` | “tooling is Dart by default” or “Python is always simpler” | Generic tooling inherits unnecessary SDK/setup, or runtime code is moved behind an unnatural bridge | Boundary-first ownership using total implementation/dependency/ops cost |
| `PIP_AT_APP_ROOT` | Quietly introducing general Python runtime/package requirements into the app tree | Python tooling becomes an undeclared second application runtime | Keep dev/test deps allowlisted and scoped; stdlib first |
| `SILENT_KNOWN_GAP` | Omitting a failing case from the suite | Green CI hides unsupported behavior | pytest `xfail(reason="known: …")` or explicit Flutter `known:/xfail:` skip + outcome receipt |
| `SKIP_EQUALS_XFAIL` | Treating all skips as known failures | Environment gates and actual known gaps become indistinguishable | Preserve passed/failed/skipped/xfailed/xpassed/error vocabulary |
| `CORRUPT_REPORT_EQUALS_EMPTY_GREEN` | Ignoring malformed test reporter lines | Truncated CI output can look like zero failures | Count malformed/non-object reporter records as errors |
| `FULL_CATALOGUE_EVERYWHERE` | Running thousands of reference-pattern tests in every compatibility lane | Suite-load/startup cost dominates useful signal | Full pinned lane + focused moving-stable/core lanes, with explicit path inventory |
| `STALE_ACTIONS_GREEN` | Reusing the latest green Actions result without checking its SHA | An older commit is mistaken for current validation | Freshness-gate receipts against git HEAD; stale inspection requires explicit opt-in |
| `PLAYWRIGHT_ARG_GREEDINESS` | Building `--project chromium <spec>` as separate argv tokens | Playwright consumes the spec as another project name | Use exact argv tests and `--project=chromium` / `--grep=value` |
| `BROWSER_MATRIX_DRIFT` | Playwright config, CI install list, Docker install list, and smoke command disagree | A configured browser silently never runs or cannot launch | Exact parity regression between project identities and installed engines |
| `ONE_ENGINE_MULTIPLATFORM` | Calling Chromium-only success “multiplatform” | Firefox/WebKit/mobile-specific failures remain invisible | Desktop Chromium/Firefox/WebKit plus high-value mobile profiles |
| `WEBKIT_EQUALS_SAFARI` | Reporting Playwright WebKit as branded Safari proof | Engine-level CI is overstated as product/device compatibility | Label it WebKit; keep physical iOS/Safari as a separate evidence tier |
| `EMULATION_EQUALS_DEVICE` | Reporting Pixel/iPhone descriptors as physical-device proof | OS picker, permissions, codec, keyboard and browser-shell differences disappear | Record browser/project/profile metadata and maintain real-device tail tests where needed |
| `MOBILE_VIEWPORT_ONLY` | Treating a narrow viewport as complete mobile validation | Touch, device semantics and engine differences are missed | Use device-oriented profiles plus explicit responsive assertions; real devices for OS boundaries |
| `SCREENSHOT_EQUALS_BEHAVIOR` | Screenshot presence is used as interaction/protocol proof | A visually plausible page can be functionally broken | DOM/accessibility/protocol assertions for behavior; screenshots/traces/videos as evidence |
| `VISUAL_DIFF_TOO_EARLY` | Making visual baselines a hard gate before deterministic rendering is stable | Noise and baseline churn dominate product signal | Establish deterministic smoke/evidence first, then stage visual regression |
| `HEAVY_E2E_AS_PR_GATE` | Building Flutter and running full browser E2E for every unrelated PR | Slow/expensive feedback and abandoned runs | Cheap install/`--list` smoke on relevant PRs; heavier E2E on explicit lanes |
| `MUTABLE_ASSET_AS_FIXTURE` | Tests assume generated build metadata is an immutable fixture | Build refresh changes test meaning | Parse through pure helpers or dedicated committed fixtures |
| `SYNTHETIC_MEDIA_EQUALS_DEVICE_SUPPORT` | Synthetic HEIC/container sniff success is reported as iPhone camera/Safari support | Codec/container detection is confused with real platform decode/import | Separate synthetic fixture, browser, native-host, and physical-device evidence |
| `DECODE_BEFORE_BUDGET` | Fully decoding untrusted media before size/pixel checks | Memory spikes and platform-specific crashes | Enforce raw byte/pixel budgets before expensive allocation where possible |
| `UI_DIRECT_PLUGIN_COUPLING` | Widgets call image picker/native APIs directly | Platform behavior cannot be faked or tested deterministically | Adapter/port boundary injected into UI/domain |
| `DEPENDENCY_FOR_CATALOGUE_COMPLETENESS` | Adding packages merely so a reference catalogue can demonstrate a feature | Runtime dependency weight grows without a real product requirement | Representative completeness; add a dependency only for a real capability |
| `COSMETIC_PERMUTATION_GROWTH` | Adding near-identical screens/styles after interaction coverage is complete | Repository size/test cost grows without new behavior | Add only materially different interaction/accessibility/layout/platform patterns |
| `DUAL_ENTRYPOINT_DRIFT` | Public Pages and production entrypoints build different route/page registries | A feature works in one deployed surface but not another | Shared route metadata/builders and parity tests |
| `PATH_FILTER_BLIND_SPOT` | CI path filters omit shared config/lock/core files that affect a lane | Relevant checks are skipped | Treat path lists as executable contracts and regression-test shared triggers where practical |

## Pytest-specific guidance

Pytest is valuable here because fixtures, parametrization, xfail, monkeypatching, temporary paths, and small stdlib-oriented tests can express tooling contracts with little ceremony. It should not become a second product runtime.

Prefer explicit fixture dependencies, narrowly scoped monkeypatches, and tests of exact observable contracts. Keep `xfail` for known unsupported behavior rather than ordinary skips. A passing xfail (`xpass`) is useful information and should remain visible.

Do not hide environment setup inside tests when the test is about argument construction or pure transformation: the Playwright CLI regression correctly stubs the installed CLI prefix and tests exact argv instead of requiring `node_modules`.

## Browser/media evidence rule

Evidence claims should name their layer:

`fixture -> parser/adapter -> Flutter runtime -> browser engine/profile -> OS/native host -> physical device/browser`

A lower layer cannot prove a higher one. In particular, synthetic HEIC, Flutter codec tests, WebKit CI, and iPhone emulation are all useful, but none alone proves a real iPhone Photos -> Safari/installed-app flow.

## Adding an incident

When a new portable failure is found, record: ID, affected PR/commit, runtime/browser/profile, observed failure, root cause, fix, regression guard, and the portable lesson. If browser-test-kit already owns an equivalent ID, prefer that shared vocabulary instead of inventing a Flutter-only synonym.
