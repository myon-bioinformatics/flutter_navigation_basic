# Pinned public Flutter: finite all-page audit

This is a **Flutter-only browser audit**, not a migration of every page to HTML. Only `../ui-showcase-html/` has an HTML counterpart. The public deployment is read-only; production Dart, deployment workflows and Pages are not changed.

## Inventory and identity

The existing `python/web_page_catalogue.py` reads the registry, route names, numbered-route TOML and public route builder. Existing `generate_page_identities.py` supplies canonical aliases and page emojis. The pinned reference is `9b38f3e935e9e171cbacc3af63f539ddce9db86b`; metadata must match before and after every observation. A stale or unavailable baseline is a failure, never an automatic baseline update.

The finite production catalogue has 215 URLs: `/screen1` through `/screen198` and 17 named URLs. Five named URLs are aliases, leaving 210 canonical page identities. The two Chromium/DPR1 conditions are 1180×757 and390×500 CSS pixels: 430 URL/viewport pairs, separately reported as420 canonical-URL pairs and10 alias pairs. Seven aliases enabled only by an E2E build are not production URLs and are not included. Route examples shown inside pages are not registered destinations.

## Measured contracts and explicit limits

Each route gets a fresh browser page/context. The runner records actual viewport/DPR, requested and observed route, page identity, shared-header bounds/non-overlap, an observed body envelope, exposed clipped semantic regions, control inventory, and screenshots. It sends measured real pointer input to the session-only favorite, real Tab/Space/Enter for keyboard reachability and focus retention, then reloads while selected to prove reset. Wheel input probes exposed vertical body regions, checks chrome remains fixed, and records whether movement and an end boundary were established.

A geometry result only covers the stated measured regions. Flutter accessibility-label dimensions are not painted glyph extents; raw body width stays diagnostic while the actual root scroll surface is checked. The observer checks the measured header frame and action buttons, not intrinsic title glyph height, for fixed positioning. A Door inside a body scroll ancestor is flowing content, not fixed chrome; its end visibility is separately required. Identified body content fully clipped behind fixed chrome without an exposed usable scroll path is a failure. Common chrome has no requirement that automatically calculated dimensions be rounded to8px multiples. Screenshot capture is not pixel equality or an accessibility certification.

Accessibility startup requires the actual unique shared title and favorite, not an arbitrary semantics node. Only the still-present unique enable-accessibility placeholder may receive real Enter input after verified deep shadow-root focus. Up to three attempts share a25s deadline, with before/after readiness diagnostics. This bootstrap does not inject focus into the favorite or manufacture a semantics tree.

No generic randomized explorer runs. Form submission, clipboard access, photo/file operations, map links, arbitrary network actions, destructive controls and persistent preference changes are not activated. Unexpected non-GET/HEAD/OPTIONS page requests are blocked and reported. There is no permission grant or secret. Every route-specific action remains `unverified` without a reviewed safe contract, and painted text/overlap beyond the measured regions remains `unverified`; neither is counted as passed. Home and specialized pages do not all have a Door footer, so footer absence is recorded rather than invented as a defect.

Unknown or unidentifiable scrolling is `unverified`, not `not_applicable`. Fit needs a positively identified region and complete exposed descendant containment; a visible fragment alone is insufficient. A wheel gesture that does not move is not proof of reaching the end unless the measured remaining scroll extent also reaches zero. Bounded probes can therefore leave genuine unknowns, which fail the required-contract aggregate instead of producing an all-green claim.

## Cost and execution boundary

The PR-only workflow uses four shards, two Chromium workers per shard, no test retries,90s per case and25min per shard. It runs only when these audit files or this workflow change; it does not add a full sweep to every ordinary Flutter PR. It uses the existing e2e Playwright development dependency and installs no new runtime dependency or Flutter SDK. The existing dependency manifest has no lockfile; actual Playwright/browser versions are included in each receipt.

`fail-fast: false` preserves the remaining route observations after a failed shard. The final aggregate requires exactly one receipt for every expected route/viewport, matching source/build/candidate identity and sibling PNG bytes/hash/dimensions. Missing, duplicate, stale, failed and unverified evidence is visible, including zero coverage. Optional unverified checks are separately counted even if all required shared contracts pass. Artifacts expire after seven days.

From the repository root:

    node --test experiments/flutter-pages-audit/audit_policy.test.cjs
    python3 -B -S experiments/flutter-pages-audit/audit_contract.test.py
    python3 -B -S experiments/flutter-pages-audit/audit_contract.py catalogue --output build/flutter-pages-audit/catalogue.json
    npm exec --prefix e2e -- playwright test --config experiments/flutter-pages-audit/playwright.config.cjs
    python3 -B -S experiments/flutter-pages-audit/audit_contract.py aggregate build/flutter-pages-audit --output build/flutter-pages-audit/summary.json

Set `CANDIDATE_SHA` to the exact full candidate commit for evidence validation. The aggregate replays saved evidence only; it does not execute current Flutter code. CI execution outcomes and the per-route receipts, not this README, establish what actually ran. No all-page pass is claimed before those results exist.
