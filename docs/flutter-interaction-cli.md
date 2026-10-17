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
