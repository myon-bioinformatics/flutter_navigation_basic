> Current status: [offline infrastructure only](OFFLINE-INFRASTRUCTURE.md). No new measurements.
> The discovery notes below describe the historical d653 baseline, not current runtime acceptance.
> Original full-audit design: [preserved #223 notes](FULL-AUDIT-HISTORY.md).

# Source-family discovery for the pinned Flutter audit

## Current scope: 24 structures × two viewports, exactly 48 cases

`family-inventory.json` lists every selected canonical route, its source-defined
initial inventory and 24 pinned source-file hashes. Generic template variants,
four interactive layouts, NativeParallel, validation/conversion source links,
Hub, Screen5/6 and Irony/MCP/UI Showcase are included. No alias or full430 pass
is implied. The reference remains `d65322c15a55a7395bb5271bc65696402bc98d29`;
the seven catalogue source hashes also remain checked. Source and live deployment
are checked before and after the run, with separate retained preflight/postflight
records; each case also requires matching live metadata before and after observation. Source selects expected
content; it does not establish observed visibility, fit or terminal reach.

The new read-only collector records semantic match counts, raw nodes, ancestry,
clipping, unsupported clip-paths, visibility, scroll containers and multipart
candidates. Every sample has its own actual screenshot and byte hash. Two
post-reload initial samples are separated by at least600ms; subsequent wheel
samples are labelled raw, not assumed stable. No new page-specific action is
activated, and no new fit/end acceptance rule is applied in this discovery.
Repeated or merged semantic labels and invisible/unidentified containers remain
unresolved rather than being inferred successful. Flutter semantic boxes do not
certify painted glyphs or complete visual overlap.

`family_contract.py` validates exactly48 receipts/PNGs, exact source/manifest and
candidate identity, expected item keys, snapshots and capture provenance. Missing,
duplicate, stale or truncated evidence invalidates collection. Collection validity
is separate from application success: required failures/unknowns still make CI
fail. Even an otherwise clean discovery is reported `discovery_only`, with
`familyBindingsVerified=false`,48 unverified family bindings and the original
full430 aggregate **failed/incomplete with382 missing pairs**. Optional actions
and painted layout remain unverified. No prior receipt is reclassified.

## Bounded execution and trigger

Two workers, zero retries, unchanged90-second case timeout,45-minute job cap,
seven-day artifacts. At most24 family snapshots per receipt are accepted, in
addition to the original screenshots. The workflow is edited-event-only, branch
`diagnostic/flutter-223-focused-d65322c1`, with the exact old title
`Diagnostic: four bounded Door-motion observations for #223` and new title
`Diagnostic: 48 source-family observations for #223 @ <full current head SHA>`.
The title SHA must equal the event PR head, which is also the checkout/candidate
SHA. Pushes, body edits, ordinary title changes and Ready transitions cannot run
the diagnostic. Publication alone is not permission to make this title change.
There is no full430 workflow on this branch and no deployment or label writer.

The bounded investigation plan is one48-case discovery and at most one further
correction round of up to48 cases after independent evidence/code review. A
full430 run is conditional on all required representative contracts genuinely
being established; it is not automatic. If semantics or time bounds cannot
prove a required contract, report the gap and keep it unknown. In particular,
last-tile reach cannot certify every unobserved middle item of a virtual list.

## Preserved four-case history

The earlier Coordinates/HTTP diagnostic is separate evidence. Run41005597396
had two HTTP classification failures; run41007188109 retained two HTTP unknowns
because80px backward travel clipped the Door40px→8px. Run41008189029 at
`1d19d9827b6759e7122d8b3b1aed39014addb1d5` passed4/4 with observed32px inverse
Door/scroller motion, full40px visibility throughout, restored endpoint and
stable headers. Those receipts and their original full430-incomplete summaries
are not rewritten. The bounded Door observer remains unchanged here; this new
48-case collector does not turn its four-case evidence into general coverage.

## Original audit design and retained limitations

This is a **Flutter-only browser audit**, not a migration of every page to HTML. Only `../ui-showcase-html/` has an HTML counterpart. The public deployment is read-only; production Dart, deployment workflows and Pages are not changed.

## Inventory and identity

The existing `python/web_page_catalogue.py` reads the registry, route names, numbered-route TOML and public route builder. Existing `generate_page_identities.py` supplies canonical aliases and page emojis. The pinned reference is `d65322c15a55a7395bb5271bc65696402bc98d29`; metadata must match before and after every observation. A stale or unavailable baseline is a failure, never an automatic baseline update.

The finite production catalogue has 215 URLs: `/screen1` through `/screen198` and 17 named URLs. Five named URLs are aliases, leaving 210 canonical page identities. The two Chromium/DPR1 conditions are 1180×757 and390×500 CSS pixels: 430 URL/viewport pairs, separately reported as420 canonical-URL pairs and10 alias pairs. Seven aliases enabled only by an E2E build are not production URLs and are not included. Route examples shown inside pages are not registered destinations.

## Measured contracts and explicit limits

Each route gets a fresh browser page/context. The runner records actual viewport/DPR, requested and observed route, page identity, shared-header bounds/non-overlap, an observed body envelope, exposed clipped semantic regions, control inventory, and screenshots. It sends measured real pointer input to the session-only favorite, real Tab/Space/Enter for keyboard reachability and focus retention, then reloads while selected to prove reset. Wheel input probes exposed vertical body regions, checks chrome remains fixed, and records whether movement and an end boundary were established.

A geometry result only covers the stated measured regions. Flutter accessibility-label dimensions are not painted glyph extents; raw body width stays diagnostic while the actual root scroll surface is checked. The observer checks the measured header frame and action buttons, not intrinsic title glyph height, for fixed positioning. A Door inside a body scroll ancestor is flowing content, not fixed chrome; its end visibility is separately required. Identified body content fully clipped behind fixed chrome without an exposed usable scroll path is a failure. Common chrome has no requirement that automatically calculated dimensions be rounded to8px multiples. Screenshot capture is not pixel equality or an accessibility certification.

Accessibility startup requires the actual unique shared title and favorite, not an arbitrary semantics node. Only the still-present unique enable-accessibility placeholder may receive real Enter input after verified deep shadow-root focus. Up to three attempts share a25s deadline, with before/after readiness diagnostics. This bootstrap does not inject focus into the favorite or manufacture a semantics tree.

No generic randomized explorer runs. Form submission, clipboard access, photo/file operations, map links, arbitrary network actions, destructive controls and persistent preference changes are not activated. Unexpected non-GET/HEAD/OPTIONS page requests are blocked and reported. There is no permission grant or secret. Every route-specific action remains `unverified` without a reviewed safe contract, and painted text/overlap beyond the measured regions remains `unverified`; neither is counted as passed. Home and specialized pages do not all have a Door footer, so footer absence is recorded rather than invented as a defect.

Unknown or unidentifiable scrolling is `unverified`, not `not_applicable`. Fit needs a positively identified region and complete exposed descendant containment; a visible fragment alone is insufficient. A wheel gesture that does not move is not proof of reaching the end unless the measured remaining scroll extent also reaches zero. Bounded probes can therefore leave genuine unknowns, which fail the required-contract aggregate instead of producing an all-green claim.

## Cost and execution boundary

The original #223 full-audit workflow (not included here) uses four shards, two Chromium workers per shard, no test retries,90s per case and25min per shard. It runs only when these audit files or this workflow change; it does not add a full sweep to every ordinary Flutter PR. It uses the existing e2e Playwright development dependency and installs no new runtime dependency or Flutter SDK. The existing dependency manifest has no lockfile; actual Playwright/browser versions are included in each receipt.

`fail-fast: false` preserves the remaining route observations after a failed shard. The final aggregate requires exactly one receipt for every expected route/viewport, matching source/build/candidate identity and sibling PNG bytes/hash/dimensions. Missing, duplicate, stale, failed and unverified evidence is visible, including zero coverage. Optional unverified checks are separately counted even if all required shared contracts pass. Artifacts expire after seven days.

From the repository root:

    node --test experiments/flutter-pages-audit/audit_policy.test.cjs
    python3 -B -S experiments/flutter-pages-audit/audit_contract.test.py
    export AUDIT_OUTPUT=build/flutter-pages-audit/family-discovery-d65322c1
    python3 -B -S experiments/flutter-pages-audit/family_contract.py preflight "$AUDIT_OUTPUT"
    python3 -B -S experiments/flutter-pages-audit/audit_contract.py catalogue --output build/flutter-pages-audit/catalogue.json
    npm exec --prefix e2e -- playwright test --config experiments/flutter-pages-audit/playwright.config.cjs
    python3 -B -S experiments/flutter-pages-audit/family_contract.py aggregate "$AUDIT_OUTPUT"

The Playwright command above is 48-case only in this branch. Set `AUDIT_OUTPUT`
to a fresh evidence directory before running; CI sets it explicitly.

Set `CANDIDATE_SHA` to the exact full candidate commit for evidence validation. The aggregate replays saved evidence only; it does not execute current Flutter code. CI execution outcomes and the per-route receipts, not this README, establish what actually ran. No all-page pass is claimed before those results exist.
