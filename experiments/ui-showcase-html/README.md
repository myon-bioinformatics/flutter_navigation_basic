# UI Showcase: dependency-free HTML comparison experiment

This is an **unpublished experiment**, not a replacement for Flutter or a new framework. It implements only the UI Showcase shared header layout, a memory-only favorite button, and the Overview body scroll region. Other controls are visibly present but disabled and accessibly described as out of scope.

The native page uses only HTML, CSS and classic JavaScript. It loads no Dart/Flutter runtime, remote font/icon assets, package runtime, build tool or framework. Browser tests use the repository's existing Playwright development dependency.

## Ownership

- Flutter remains the reference implementation. The published reference must report the exact SHA in provenance.json; changed or missing metadata fails the comparison, rather than silently updating the baseline.
- Three small web-ui CSS files are pinned byte-for-byte, with MIT notice and hashes in provenance.json. Stable ui-* classes and the base/reset are reused. Most visual component declarations are overridden by this consumer's layout; this does **not** demonstrate a reusable common header implementation.
- Existing e2e/utils/interaction.mjs supplies BTK-derived measured real pointer input, retaining its existing provenance. The native adapter uses btk-platform-adapter/1 and native data-testid selectors; its favorite postcondition observes aria-label. A separate pinned BTK checkout tests the actual provenance reader without copying that runner into Flutter.
- Route-specific content, state and layout stay in this experiment. Common extraction should wait until another consumer validates the same boundary.

## Files and local checks

From the repository root:

    node --test experiments/ui-showcase-html/state.test.cjs
    BTK_PLATFORM_ADAPTER=/path/to/pinned/browser-test-kit/scripts/platform_adapter.py python experiments/ui-showcase-html/adapter.test.py
    node --check experiments/ui-showcase-html/state.js
    node --check experiments/ui-showcase-html/app.js

The Python regression uses a fake HTTP response through the actual pinned BTK reader. It tests nested metadata traversal, not live HTTP or browser behavior. BTK source revision: f37c438a5285a03b39adda052ad14598a2ca8966.

The focused comparison workflow installs the **existing** e2e Playwright dependency, records its resolved version, serves this directory locally, and compares it against the published Flutter reference. The repository currently has no e2e lockfile; installation follows the existing npm install convention without adding a dependency or modifying the manifest.

## Evidence boundary and remaining limits

Before CI, ten Node checks (including pinned-vendor integrity) and two Python adapter-reader regressions passed. Independent source review found and fixed a provenance-key-path error. Live cloud-browser observations were made only on Flutter at 1180×757 CSS pixels, DPR1: primary header56px, secondary48px, and favorite40×40 at x1100/y8. Mouse click, Space, Enter and reload reset were observed on Flutter. The local native page could not be reached from that cloud browser. **These prior observations are not proof of native browser parity.**

The CI test and uploaded artifacts, rather than this static README, establish what browser checks ran for each commit. Measurements include build identity, viewport/DPR, bounding boxes, native hit visibility, input postconditions, fixed chrome during body scrolling and screenshots. Container-edge comparisons use a declared tolerance; screenshots are for visual review and are not pixel-equality approval. A successful selected-control check does not certify every Flutter behavior, painted glyph, screen reader, browser engine or physical device.

Known limits:
- Home, Back, Menu, theme, section navigation and footer navigation are not migrated.
- English and light presentation only. The Overview and footer copy describe Flutter, not this HTML implementation.
- Native favorite uses aria-pressed; Flutter exposes aria-current. Their accessibility trees are intentionally not byte-identical.
- Native system-font fallback, original SVG icons, approximate colors and native select rendering differ from Flutter.
- Below900px the rail is hidden; at1180px it is256px plus divider. The intermediate80px rail is provisional until measured.
- Normal fixed chrome consumes 338px at compact width and 258px at rail width. At heights of 458px or less (compact), or 378px or less (rail), the native experiment instead lets its document scroll and its Overview grow with content, with a 120px minimum body track. This avoids an unreachable zero-height body. Header/footer are not fixed in this fallback, and Flutter-equivalent geometry is not claimed there.
- No cache, async state framework, general router, persisted favorites or production component extraction is added.

The separate native-only responsive project checks the 899/900px and 1179/1180px boundaries at 757px height, a 320×500px narrow window, and short windows of 390×320px and 900×240px. It checks clipping/overlap, measured pointer hits, keyboard favorite operation, real wheel/PageDown/End scrolling, and reachability of the final text and footer. It does not duplicate the two existing Flutter comparison projects or assert font/pixel equality. These new cases are test coverage, not a claim that they passed before CI runs; arbitrary zoom, touch input, and assistive technology remain outside the evidence.

## Publication safety

The only new workflow is a pull-request comparison job with contents:read. It has no Pages deployment, write permission or deployment trigger. Existing Flutter, Pages, runtime source and package manifests are unchanged. The reference URL is read-only except for session-local favorite interaction. This experiment is not added to Flutter's assets or build output.

Sources:
- [Flutter header](https://github.com/myon-bioinformatics/flutter_navigation_basic/blob/9b38f3e935e9e171cbacc3af63f539ddce9db86b/lib/shared/widgets/standard_page_header.dart)
- [Flutter UI Showcase](https://github.com/myon-bioinformatics/flutter_navigation_basic/blob/9b38f3e935e9e171cbacc3af63f539ddce9db86b/lib/screens/ui_showcase_screen.dart)
- [web-ui contract](https://github.com/myon-bioinformatics/web-ui/blob/6c51fd53a11b24b2f8d0205a2a9c597fb5f2b558/contract/v1/contract.json)
- [BTK adapters](https://github.com/myon-bioinformatics/browser-test-kit/blob/f37c438a5285a03b39adda052ad14598a2ca8966/docs/platform-adapters.md)
