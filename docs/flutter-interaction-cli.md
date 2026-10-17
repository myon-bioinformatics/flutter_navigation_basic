# Flutter Web native gesture and animation via a Python one-liner

**Purpose:** Run real 171–175 / 183–184 Flutter controls under browser automation.
The user-facing /screenNNN catalogue renders GenericScreen; those routes are
not equivalent to the individual pattern View. E2E-only routes are
/#/examples/data-processing-interactions/{171,172,173,174,175,183,184}.
No production route is added; the route exists only with --dart-define=E2E=true.

Initial setup (Flutter, Node, and a real browser are required at least once):
  cd e2e && npm ci && npx playwright install chromium && cd ..
  flutter build web --release -t lib/main.dart --dart-define=E2E=true --base-href "/"
  python -m http.server 8080 --bind 127.0.0.1 --directory build/web

With the server running, execute any of these from the repo root:
  python python/playwright.py interaction --project chromium --kind portable
  python python/playwright.py interaction --project chromium --kind gesture
  python python/playwright.py interaction --project chromium --kind all

Direct Node CLI, identical test file and existing Playwright install:
  node e2e/node_modules/@playwright/test/cli.js test --config e2e/playwright.config.ts --project=chromium --grep=@gesture e2e/tests/pattern_interactions.spec.ts

The Python launcher itself is **stdlib-only** and invokes the exact Node
Playwright executable. It does not remove the requirement for the optional
browser dependency and installed browser binaries.

The seven scenarios verify screen behavior, not raw Dart source text:
- 171 / 172 / 184: actual pointer drag that must change displayed list order
- 173: press/hold and drag between grid cells, asserting changed order
- 174 / 175: insertion/removal with Flutter AnimatedList
- 183: select an item and batch delete it

All are available as Flutter Widget tests without Playwright:
  flutter test test/features/data_processing_patterns/interactive_pattern_example_test.dart

The core widget and the E2E route are Flutter-specific. The Python wrapper and
Playwright mouse/bounding-box helper are candidates for browser-test-kit
extraction; do **not** vendor a second Playwright runtime into the Flutter repo.
Inspect and collect reports, screenshots, or traces before claiming an actual
interaction passed on a given browser. Mobile projects emulate the browser;
they are not evidence from physical iOS/Android hardware.

Re-running a test against an unchanged build does not require rebuilding.
Changing Dart does require hot reload/recompile or rebuilding web artifacts.
Web pages must not get an unrestricted endpoint for shell/Python CLI execution.
## Test an existing Web build without Flutter

The existing Python wrapper can run the image-ingress and clipboard checks
against a local server or a published Pages build. It starts Node/Playwright,
not Flutter, Dart, Xcode, or an Android build. The URL selects existing bytes;
testing production does not validate an unbuilt local patch.

Install the browser test tools once (`e2e` already declares Playwright):

```bash
cd e2e
npm install
npx playwright install --only-shell chromium
cd ..
```

Then the normal one-line check is:

```bash
python python/playwright.py test --base-url https://myon-bioinformatics.github.io/flutter_navigation_basic/ --light --project chromium --grep "Clipboard image bridge" tests/photo_studio_ingress.spec.ts
```

`--light` disables video and traces; assertions and failure screenshots remain.
The tests use the committed 64x32 PNG, exercise pick/resize and Base64/copy/paste,
and check encoded PNG dimensions and corner pixels. A successful text decode
alone is not image-rendering or PNG-encoding evidence. Headless Chromium still
requires a browser engine, but needs no mobile SDK or Flutter build.

For browserless Python/Node checks use the existing entrypoint:

```bash
python python/test.py --python --node -x
```

These results have different scopes: unit/contract checks, existing-Web browser
checks, and native iOS/Android checks. Captured build logs and old artifacts
cannot establish that changed native code still compiles. Keep the native
checks for native inputs/releases. Cross-language conversion should begin with
bounded pure functions and shared JSON inputs/outputs; this change does not
implement a general Dart-to-Kotlin/Swift translator.

## Observe every public page, then check the saved evidence without a browser

The existing route declarations currently describe **215 public routes**: all
198 numbered routes plus canonical tools, catalogue pages and legacy aliases.
`pages` reads `RouteNames`, `AppRouteRegistry`, `AppRoutes`' mock API alias and
`ci/numbered_routes.toml`; it does not maintain another hand-written route list.
E2E-only aliases and arbitrary query/input combinations are outside this list.

After the one-time Node/browser setup above:

```bash
python python/playwright.py pages --base-url https://myon-bioinformatics.github.io/flutter_navigation_basic/ --light
```

This defaults to one headless Chromium project, reuses one browser process,
and starts no Flutter/native build. Each route gets an isolated page/context.
Use repeated `--route /hub --route /tools/media/photo-studio` to select routes,
`--project webkit` for another installed engine, or `-- --list` to list without
launching a browser. Extra Playwright flags follow `--`, for example
`-- --output /tmp/pages-observation --max-failures=3`.

Each route writes `web-observation.json` and a viewport PNG beneath the normal
Playwright output directory (`e2e/test-results` by default), with HTML-report
attachments. The receipt records the URL, served build SHA, route-source hashes,
test outcome, fixture identity when applicable, browser/Node version, viewport,
device scale, semantic control labels/identifiers and CSS-pixel boxes, bounded
console errors/warnings and failed requests, and the screenshot SHA-256. It
collects existing Flutter accessibility metadata rather than changing Dart.
Input values and clipboard contents are not collected. Console messages may
still include app-generated diagnostics; use dedicated test data.

The existing Photo Studio/clipboard ingress tests attach the same receipts for
actual image operations. The all-page sweep is a load/display smoke check;
it does not automatically click every button, open every dropdown, or prove
that every feature works. A viewport capture does not inspect content that has
not been scrolled into view or lazily created. Mobile projects emulate Web;
these receipts do not claim native iOS/Android execution.

Run the following as often as needed, with **only Python stdlib**:

```bash
python -S python/check_web_observations.py e2e/test-results --expected-sha FULL_DEPLOYED_COMMIT_SHA
python -S python/check_web_observations.py NEW_PAGES --baseline OLD_PAGES --tolerance 2
```

The first command checks all saved pages against their recorded catalogue,
rejecting missing/duplicate pages, mixed catalogues/builds, failed/skipped tests,
incomplete captures, uncaught JS errors, and altered/missing screenshots.
Start a full sweep in a fresh output directory; do not mix ingress receipts,
partial/sharded output, or previous runs in that directory. Combine all shards
before checking coverage. A filtered sweep verifies only its selected routes.
The second accepts whole capture directories or individual receipt files, and
compares control counts, labels, visibility and geometry in CSS
pixels; viewport/device scale and project must match. Browser-version changes
remain in the receipts for review; this is not pixel equivalence.

The equivalent existing Python entrypoint is
`python python/playwright.py check-observation PATH ...`. It imports no browser
package and starts no Node process. Success certifies the **saved observation**,
not newly edited Dart, a new render, or a native build. Browser recapture is
still needed after a relevant UI/runtime change. Old screenshots/logs are not
a substitute for compiling changed native code.

All-page capture uses the manual **Published Web page observations** workflow,
with the same command. Changes to the collector itself also exercise it against
the published Pages build in one Chromium job; ordinary app PRs do not acquire
a new 215-page browser matrix. This verifies collector code and the deployed
site, not the unbuilt app changes in a PR. The existing ingress lane exercises the collector; the existing
Python oracle lane checks receipt validation and coverage offline. Retain useful
capture directories as normal CI artifacts or baselines outside the source tree;
do not commit accumulated videos, screenshots or build caches.


### Bounded parallel workers and replayable exploration

The default worker count is min(4, the available CPUs, one per 2 GiB of
reported/constrained memory), with a minimum of one. This is a conservative
estimate, not an OOM guarantee. Set `FLUTTER_WEB_WORKERS=1` or pass Playwright's
`--workers=1` after `--` to diagnose resource pressure. Explicit environment
values from 1 through 32 override automatic selection. Portable regression
cases and route observations opt into per-case parallelism; tests that share a
server retain their existing ordering. Clipboard writers use Playwright's
`system-clipboard` lock across projects/workers.

Playwright reuses healthy OS workers and browsers, creates/tears down an
isolated context/page per test, and replaces a worker after failure. Completed
slots take the next test without waiting for an entire batch. Recreating a
healthy browser for every route would add startup cost. No new process
supervisor or dependencies are introduced. Existing JUnit failures remain
failures; retries stay zero and remaining independent tests still run.

```bash
python python/playwright.py pages --base-url https://myon-bioinformatics.github.io/flutter_navigation_basic/ --light --explore-steps 3 --seed recorded-seed -- --workers=2
```

The published-page workflow uses three bounded exploratory actions per route.
Its seed changes with run ID/attempt; manual dispatch accepts a replay seed.
Actions choose among visible editable fields, selected local buttons, Tab,
Escape and scrolling. Generated field values include empty, numeric, Japanese,
emoji and long text. The runner re-inventories after each operation and reuses
the existing real-pointer helper. Each test attaches `exploration.json` with
seed, route, actual action/value/label, errors and worker/slot. JUnit testcase
properties include the seed, route and step budget, and link the action receipt. This is sampled
exploration, not exhaustive paths or an assertion that every business result
is correct. File pickers, exports, clipboard and unrestricted deletion remain
in dedicated regression tests. DOM changes may change candidate selection;
replay requires the same deployed build/browser/viewport as well as seed.

Smoke-only runs remain `--explore-steps 0` (CLI default). Exploration can change
visible state, so use smoke-only captures for a stable geometry baseline, or
compare captures with the same seed, build and exploration settings. A control
that navigates away is followed by returning to the original route before the
normal observation fixture captures its receipt. Browserless scheduler checks
run with `cd e2e && node --test unit_tests/execution.test.mjs`; these start real
Playwright worker processes without installing or launching a browser engine.
