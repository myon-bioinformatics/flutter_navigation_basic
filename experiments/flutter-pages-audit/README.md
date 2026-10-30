# Focused diagnostic for the pinned Flutter audit

## This diagnostic branch: four cases, not430

The default Playwright config in this branch deliberately selects only Coordinates
(`/tools/location/coordinates`) and canonical HTTP (`/tools/http/request-draft`),
at the two reference viewports: **exactly four cases**, two workers, zero retries.
Aliases and the other426 pairs are not measured. The reviewed deployed reference
is `d65322c15a55a7395bb5271bc65696402bc98d29`; the seven catalogue source hashes
are pinned in `focused-baseline.json`. There is no automatically-follow-latest baseline.

The initial opened-event diagnostic ran once with two Coordinates passes and two
HTTP classification failures. The second run retained two HTTP unknowns because
its80px backward gesture clipped the Door40px→8px; all prior receipts remain
unchanged. The proposed next
workflow runs only on the exact title transition from
`Diagnostic: four Flutter Door-motion observations for #223` to
`Diagnostic: four bounded Door-motion observations for #223`, on branch
`diagnostic/flutter-223-focused-d65322c1`. Publication/synchronization alone,
body edits and later pushes do not trigger another browser run. A new owner grant
is required before publishing this revision and making that one title change. It is read-only, has a10-minute job bound and retains
artifacts for7 days. It does not deploy and must not be merged by default.
The original full430 PR workflow is absent from this branch.

`focused_contract.py aggregate OUTPUT` validates the same full receipt/check/PNG
contracts as the original aggregator, then checks that precisely the intended4
pairs exist. Its focused outcome remains failed/unverified when any required
check fails/is unknown. It also saves the original full430 aggregate unchanged:
**failed/incomplete with426 missing**, even if the four-case diagnostic passes.
No result reclassifies historical9b38f3e evidence or removes #223's failing label.
Optional page-action/painted-layout checks remain unknown.

The local browser attempt could not launch due to a sandbox socket restriction;
no page receipts were collected. Source/policy tests and exact4-case discovery
passed; browser proof must come from the separately authorized diagnostic run.

## Proposed observable Door-motion witness

When an initially unexposed Door first appears inside a body scroller, ancestry
alone is not a pass. The proposed observer sends two bounded real wheel gestures
(back and forward by the same measured distance, capped at32px), retaining the same Door/scroller IDs and measuring
inverse Door displacement versus scroll offset on both legs. It requires at
least12px observed movement, stable chrome, restored endpoint, and complete
final clipped visibility. Each leg has bounded3-second settling; the existing
90-second case timeout is unchanged. The planned distance intersects the viewport,
body envelope, region clip and all measured scroll-ancestor clips, preserving a4px
margin; less than12px available travel sends no wheel input and stays unknown.
Missing/insufficient evidence stays unknown,
and measured chrome drift fails. There is no source/route whitelist substitute.
No retained receipt contains a fully visible bounded-distance witness; fresh
authorized browser evidence is required. No general430-case or page-action pass is implied.

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
    python3 -B -S experiments/flutter-pages-audit/audit_contract.py catalogue --output build/flutter-pages-audit/catalogue.json
    npm exec --prefix e2e -- playwright test --config experiments/flutter-pages-audit/playwright.config.cjs
    python3 -B -S experiments/flutter-pages-audit/focused_contract.py aggregate build/flutter-pages-audit

The Playwright command above is four-case only in this branch. Use `AUDIT_OUTPUT`
consistently with the focused aggregate argument; CI sets it explicitly.

Set `CANDIDATE_SHA` to the exact full candidate commit for evidence validation. The aggregate replays saved evidence only; it does not execute current Flutter code. CI execution outcomes and the per-route receipts, not this README, establish what actually ran. No all-page pass is claimed before those results exist.
