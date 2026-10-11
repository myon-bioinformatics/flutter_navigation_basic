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
  python tool/python/playwright.py interaction --project chromium --kind portable
  python tool/python/playwright.py interaction --project chromium --kind gesture
  python tool/python/playwright.py interaction --project chromium --kind all

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
