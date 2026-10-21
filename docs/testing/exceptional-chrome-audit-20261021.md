# Specialized screen chrome audit — 2026-10-21 (#183)

## Decision

Keep the application layout unchanged. Headers already delegate to
`StandardPageHeader`; the three specialized Scaffolds do not contain duplicate
footer implementations. Adding a Door there would add navigation and reserve
body space, rather than remove equivalent code. An absent Door is recorded as
an observation, not automatically asserted to be a defect.

The focused change adds reproducible browser comparisons and regression
coverage to the existing Playwright lane. It preserves Photo Studio's inline
selector and dirty-state gate, pattern gestures/state, and Python source links.
Issue #183 remains the specialized audit ledger; this sample is not a visual
certification of all 198 routes.

## Baseline identity and earlier evidence

- Current source and deployed Pages revision:
  `81e2f9c0ab286d4f0103024b00657d3135aa0928`.
- [Pages run 39547097840](https://github.com/myon-bioinformatics/flutter_navigation_basic/actions/runs/39547097840),
  `github-pages` artifact **12322710240**, ZIP digest
  `sha256:4a034a334bfd09b7493e407a2f5d068a9d85242a96ad076833d5f84fb287b5fb`.
  Embedded `assets/assets/diagnostics/build_metadata.json` identifies this SHA;
  the observed deployed metadata identifies the same SHA.
- PR #182 head: `806e57e8dc0b4120c79467246c0c3e4e285ca8f1`.
  [Non-Dart run 38471162895](https://github.com/myon-bioinformatics/flutter_navigation_basic/actions/runs/38471162895),
  report artifact **11852573264**, JUnit artifact **11852573254**.
- Re-downloaded and inspected these earlier artifacts: portable JUnit has
  **195 tests = 189 passed / 0 failures / 0 errors / 6 skipped**; interaction
  portable and gesture reports each have **4 passed**. Skips are not successes.
- The five `route-audit.json` files are complete. Recomputed all **25** route
  PNG byte counts/SHA-256 values and decoded their PNG structure. Re-ran the
  current existing header oracle against all **70** earlier header receipts:
  **70 passed / 0 failed**. Visually compared Photo Studio and the destination
  PNGs for all five projects. This reuses old evidence; it is not a fresh
  five-browser run on current main.
- Earlier receipts identify PR synthetic merge SHA
  `2a33eb3207b812a1563880c2e7e85fd94990f326`, rather than a direct main build.
  Their destination routes include GenericScreen pages and PatternSourceLinks
  105. Reaching 105 from Door never proved onward Door navigation from 105.

## Fresh, focused observation

`e2e/tests/exceptional_chrome.spec.ts` compares `/screen6` with `/screen136`,
`137`, `171`, `173`, `174`, `183`, `91`, and `109` in the **same browser/profile**.
It captures the initial viewport and a viewport of the same width, height
**320 CSS px**. This reduced-height observation is not an on-screen-keyboard test.

Every case reuses `python/header_contracts.py`, compares Home/Favorite/Menu
geometry to the standard page, and leaves through the real shared Home button
and confirmation. The receipt records the number of Door fields separately
from navigation success. No test requires a deliberate exception to remain
footer-less forever.

| Family / representative | Responsibility and observed operation | Classification |
| --- | --- | --- |
| GenericScreen / 6 | Shared header, body and fixed `StandardPageFooter`; reference geometry/PNG | Retain the standard shell/footer |
| InteractivePatternExample / 171, 173 | `Expanded` list/grid; real mouse reorder and 700 ms long-press grid swap; state changes to B,A,C | Retain independent gesture/body layout. A footer would reduce its bounded gesture/scroll area |
| InteractivePatternExample / 174, 183 | Animated insertion produces N1,A,B,C; selection then batch deletion produces B,C. Last-item scroll is recorded after the action | Retain `AnimatedList` key/state and selection handling; no shell substitution |
| NativeParallelPatternExample / 136, 137 | Run button and result remain usable at short height; Web fallback / compute each produces 55 and re-enables Run | Candidate for an **additive** fixed footer, not a proven equivalent replacement. Retain current body until footer reservation, text scaling and native running state are tested |
| PatternSourceLinks / 91, 109 | Long URLs, copy controls, ListView end reachability. Chromium copies the exact source document URL into the system clipboard | Candidate for a shared shell with an independently scrolling body. Reserve-footer/selection equivalence has not been demonstrated; retain current ListView and SOURCE_REF links |
| Photo Studio | Body-end Door after scrolling; import makes the page dirty, Cancel keeps image/Undo, Discard reaches Clipboard Shelf | Keep inline selector plus `beforeNavigate`. StandardPageFooter has no corresponding guard API and fixed placement changes canvas/body space |
| UI Showcase / Irony Generator | Previous evidence shows separate section navigation / positioned Door respectively; these structures are still present | Retain dedicated layout. This slice does not re-certify their gestures or whole-page scrolling |

The browser drag tests explicitly use **mouse** input even on the mobile
Chromium/WebKit emulations. They do not prove native touch dragging. Mobile
WebKit has no Playwright wheel support: receipts distinguish semantics scrolling
from native mouse/touch input. Its source-link geometry does not claim a real
clipboard copy. Chromium clipboard cases use the existing `system-clipboard`
lock so the parallel suite cannot overwrite their sentinels.

The additional Photo Studio case lives in
`home_discovery_journeys.spec.ts`, reusing the existing measured Door helpers,
fixture image and import observation. It captures dirty Door, both leave
confirmations, and the actual Discard destination. Import midway through the
body stops scrolling when visible; it does not use the body-end Door scroll
algorithm. Importing a fixture is distinct from testing canvas drag behavior.

## Receipts and reproduction

The existing Non-Dart portable lane now includes the new specification. No
new runner, dependency or artifact format replaces the existing receipts.

```sh
cd e2e
npx playwright test tests/exceptional_chrome.spec.ts --project=chromium
npx playwright test tests/home_discovery_journeys.spec.ts --grep 'dirty Door'
```

Per project/case, the ordinary `playwright-e2e-report` artifact retains:

- `standard-header.json`, `exception-header.json`, `short-header.json` and PNGs;
- `chrome-audit.json`: project/browser, CI identity, geometry, pointer/scroll
  inputs, source-copy values where tested, PNG sizes and hashes;
- `photo-door-audit.json` and PNGs for dirty Door Cancel/Discard;
- ordinary failure screenshots/context if a case fails. Only a completed case
  sets `stage=complete`.

Local observation serves the unmodified Pages artifact on loopback, fulfills
CanvasKit CDN requests from that artifact's matching local files, and caches
original font responses. It uses Playwright 1.64 with Chromium headless shell
133, locale en-US, 1280×720 desktop and 412×839 mobile Chromium emulation,
then short height 320. Asset URL remapping/local origin is a harness difference,
not a new app build. The local run and the eventual PR CI run must be reported
separately; local results are not five-engine CI success.

## Remaining scope

No claim is made about physical devices, mobile touch swipes, text-scale
accessibility, keyboard appearance, every locale or all 198 screens. The
native transient running frame and isolate scheduling remain the responsibility
of existing Flutter tests. Existing Photo Studio canvas/undo/leave Widget tests
remain in CI; this local environment has no Flutter SDK and did not re-run them.
A future footer feature must verify reduced body area and lifecycle guards
before changing these retained exceptions.
