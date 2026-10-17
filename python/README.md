# Python test / oracle tooling

This directory holds **dev/test-only** helpers for light calculation checks,
golden/oracle tests, and GitHub Actions status lookup.

## Tooling language split (stdlib-first)

Prefer each language's **standard library** for scripts/tests that do not need
a compile step. Avoid new environment dependencies unless allowlisted.

| Language | Prefer for | Notes |
| --- | --- | --- |
| **Dart / Flutter** | Shipped Flutter runtime, widgets/navigation, Flutter-aware tooling | Production app source of truth where Flutter owns the capability |
| **Python stdlib** | Generic dev/test tooling: Actions, JSON/zip/filesystem/network, fixtures, reports, reference oracles | No pip required; may take ownership from Dart tooling when it materially simplifies maintenance |
| **Python + allowlisted pip** | Pytest/browser/oracle tooling under `python/requirements.txt` | Not ordinary client runtime; one production source of truth remains mandatory |
| **Deno** (optional) | TS one-file fetch/CLI scripts with zero `node_modules` | OK when JS/TS + std fetch fits better than Python |

Root-level / app-tree `requirements.txt` remains prohibited.

## Photo Studio import-compat fixtures

Synthetic (no personal photos / GPS) fixtures for format probing:

```bash
python3 -m pip install -r python/requirements.txt  # Pillow for progressive JPEG
# also needs ffmpeg + heif-enc (libheif-plugin-x265) on the host
python3 python/generate_photo_import_fixtures.py
```

Writes binaries + `cases.json` only. Measured outcomes live in
`test/fixtures/photo_studio/import_compat/evidence/*.json` (never overwritten).
Human matrix: `docs/photo-import-compatibility.md`.

## Setup (only needed for pytest oracles)

```bash
python3 -m venv .venv-python
source .venv-python/bin/activate
python -m pip install -r python/requirements.txt
```

`--actions-latest` itself is **stdlib + `gh` or `GITHUB_TOKEN`** and does not need the venv.

## One-command entrypoint

```bash
# Local calculation oracles (default)
python3 python/test.py
# same via Dart dispatcher
dart run build_tools/dev.dart py

# Latest GitHub Actions status for this branch
python3 python/test.py --actions-latest
python3 python/test.py --actions-latest --json
python3 python/test.py --actions-latest --write build/diagnostics/actions-latest.json
dart run build_tools/dev.dart py --actions-latest --json

# Freshness: by default the run head_sha must equal git HEAD.
# Override only when intentionally inspecting an older green run:
python3 python/test.py --actions-latest --allow-stale

# Download archived CI artifact from that run (also freshness-gated)
python3 python/test.py --actions-latest --workflow "Non-Dart checks" --download-artifact python-oracle-summary

# Pytest mode switch via conftest
python3 python/test.py --pytest -- --oracle-mode=local
python3 python/test.py --pytest -- --oracle-mode=actions
python3 python/test.py --pytest -- --oracle-mode=actions --actions-summary build/diagnostics/actions-latest.json

# Outcome tallies (passed/failed/skipped/xfailed/xpassed/error)
python3 python/test.py --pytest -- --outcomes-json build/diagnostics/python-oracle/pytest_outcomes.json
# Flutter JSON reporter → same status vocabulary (known:/xfail: skips count as xfailed)
flutter test --file-reporter=json:build/diagnostics/flutter-test.json test/shared
python3 python/test.py --flutter-outcomes build/diagnostics/flutter-test.json --json
```

## Outcome statuses

Aligned with pytest’s mix:

| Status | Meaning |
| --- | --- |
| `passed` | Asserted green |
| `failed` | Unexpected failure |
| `skipped` | Not run (mode/env gate, etc.) |
| `xfailed` | Expected fail / known gap (`pytest.mark.xfail`, or Flutter skip reason `known:` / `xfail:`) |
| `xpassed` | Marked xfail but passed |
| `error` | Collection/setup error |

CI uploads these counts inside the `python-oracle-summary` artifact (`pytest_outcomes.json` + `receipt.json`).

Primary CI home for this directory is `.github/workflows/non-dart.yml` (stdlib Docker job + pytest).
The full pytest suite and its `python-oracle-summary` artifact run only in Non-Dart checks.
Flutter retains the stdlib checks of the production Dart contracts. Pages gates on
the successful Flutter run for its target SHA and regenerates canonical metadata
for that checkout; it does not download the Python oracle summary. A successful
Flutter/Pages run therefore does not imply that the separate Non-Dart workflow
has succeeded. Select `--workflow "Non-Dart checks"` when retrieving Python evidence;
the default Actions status view remains the Flutter workflow.

Flutter/`package:test` has no native xfail/xpass. The Flutter JSON tally therefore
keeps the same keys for a shared vocabulary, but **`xpassed` stays 0** in practice:
only `known:` / `xfail:` *skips* are remapped to `xfailed`. Unexpected passes of
those skips are not observable the way pytest `xpass` is.

Malformed or non-object NDJSON lines in Flutter reporter output are counted as
`error` (not ignored), so a truncated/corrupt file cannot look like a green empty run.

## Useful stdlib one-liners

```bash
# Pretty-print / validate JSON receipts and goldens
python3 -m json.tool python/fixtures/coordinate_area_cases.json | head
python3 -m json.tool build/diagnostics/actions-latest.json > /dev/null

# Inspect / pack diagnostic zips
python3 -m zipfile -l build/diagnostics/some.zip
python3 -m zipfile -c build/diagnostics/bundle.zip build/diagnostics/python-oracle

# Tiny static server for local web artifacts
python3 -m http.server 8000 --directory build/web
```

## Build artifact report (stdlib)

Report-only size summary for a built tree (for example `build/web`). Distinct
from `build_tools/build_metadata.dart` / `build_tools/inspect.dart`. No hard budgets; dual CI
builds are not required.

```bash
python3 python/build_artifact_report.py --root build/web --output build/diagnostics/web-build.json
python3 python/build_artifact_report.py --compare before.json after.json
```

## Current coverage

- `fixtures/coordinate_area_cases.json`: shared golden vectors for zoom / span policy
  (Dart `test/coordinate_tool/` is the formula source of truth)
- Photo Studio geometry: Dart-only (`test/photo_studio/studio_geometry_test.dart`);
  no Python fixture or oracle
- `tests/test_coordinate_area.py`: stdlib structural checks on the shared JSON
  (unique ids, required keys/types; no midpoint/zoom math)
- `build_artifact_report.py` / `tests/test_build_artifact_report.py`: web artifact
  size report + before/after compare
- `tests/test_actions_latest.py`: optional CI-green assertion (`--oracle-mode=actions`)
- `tests/test_outcomes.py` / `outcomes.py`: multi-status tallies including xfail/known
- `tests/test_known_xfail_example.py`: documents `xfail(reason="known: …")` for receipts
- `actions_latest.py` / `test.py`: fetch latest Actions jobs + optional artifact download
- CI uploads `python-oracle-summary` for later `--download-artifact` use
- Latest-stable Flutter shards run **core** paths only (`ci/flutter_core_test_paths.txt`); pattern catalogues stay on pinned shards


## Shared repository-metadata vendor lock

Vendored modules under `python/vendor/` are test/build inputs copied from
public upstream repositories. Their exact upstream commit, Git blob and SHA-256
identities, plus each upstream LICENSE, are recorded in
`python/vendor.lock.json` (`vendor-lock/1`); every entry pins a full
40-hex upstream commit in `ref` and `commit`. Repository metadata is produced by the vendored
`gh_identity.py`; the former Ironmate modules (`73157cb7`) were removed after
the switch (#169), and their output bytes remain pinned as frozen hashes in
`tests/test_flutter_navigation_basic_repository_metadata.py`.

Ordinary Non-Dart CI uses the shared stdlib-only `vendor_sync.py` pinned at
`1eda992aa6fa31a902e2c06428e53ab17e8fe3c1`. A locked lane verifies the manifest,
recreates the checked-in files from their pinned commits, and runs the metadata
regressions. The pytest lane runs the existing Python suite against the
checked-in baseline only (no upstream `update` lane). CI never writes back to
the repository, pushes a branch, opens a PR, or requires an update token.
Pages and application builds continue to use the checked-in baseline.


## Lock-derived evidence staging

Vendor artifact membership is now derived exclusively by the parent
`vendor_stage.py`, checked out with `vendor_sync.py` at full commit
`1eda992aa6fa31a902e2c06428e53ab17e8fe3c1`. Workflow uploads point to its generated
directory; adding a locked source or LICENSE needs no upload path-list edit.
Artifact names and repository-relative paths inside each artifact are preserved.
`vendor-evidence.json` is additional metadata with byte hashes and separate
locked/candidate, runtime receipt, and legacy projection classifications.

Staging runs even after a failed test, verifies every locked byte, and fails
nonzero on missing or modified members. It does not certify tests or promotion.
Locked runs exclude promotion receipts; the former candidate lane was removed.
Legacy projection formats, when present, remain consumer-owned outputs of the
lock. Exact source pins, LICENSEs, test-only dependencies and Pages/MCP/runtime
behavior are unchanged. Central topology intent is owned by the parent's
`vendor-consumers.json`; recommended baselines belong to `vendor-catalog.json`;
this consumer's lock remains the authority for adopted bytes.

## Screenshot comparison

`python3 python/image_diff.py A B [--clip X,Y,W,H --viewport-width W] [--tolerance N]` prints one line
(`changed`, `ratio`, `bbox`, `max_delta`) for two images; either side may be `ZIP::member`, so a downloaded
Playwright evidence zip is compared without extracting it. `--clip` is in CSS px and is scaled by the image's
real width, so DPR-2 screenshots are clipped correctly. Exit 0 identical, 1 differs, 2 input error.

The CLI delegates to `vendor/image_diff.py`, copied byte-for-byte from
`browser-test-kit` `scripts/image_diff.py` at the commit pinned in
`vendor.lock.json` (Git blob and SHA-256 recorded there). The existing
`vendor/browser-test-kit-LICENSE` covers this source. Tests are adapted from
`tests/python/test_flutter_navigation_basic_image_diff.py` at the same adoption commit (paths/import
target only), with additional RGBA channel regressions. The maximum RGBA channel
delta must exceed tolerance (0..255). Files and uncompressed ZIP members have a
64 MiB pre/post-read limit. Nonfinite numbers and invalid/out-of-bounds clips
return exit 2. DPR crops use rounded pixels. Implementation changes belong to
browser-test-kit; Flutter owns only its CLI adapter.

## Repository layout

Python tooling, including timezone generators and fixtures, lives here.
Build/diagnostic Dart sources live in `build_tools/`; generated output remains
in ignored `build/`. JavaScript helpers, CI inputs and Docker scripts live in
`javascript/`, `ci/` and `docker/`. There is no `tool/` compatibility tree.

## Actual Dart contracts without Flutter

```bash
python -S python/dart_contracts.py
```

This stdlib Python entrypoint runs the existing production Dart exporter using
only a Dart SDK, then applies the existing independent Python oracle: 594 actual
models/services, 595 JUnit checks including inventory. It does not install
Flutter, invoke `pub get`, download packages, start a browser or build an app.
`--dart /path/to/dart` can reuse an installed SDK. The explicit package config
maps this checkout's real `lib/`; there is no copied model or fake Flutter SDK.
The source preflight rejects external packages and non-VM SDK imports; the real
Dart compiler remains authoritative if a new dependency becomes unsupported.

```bash
python -S python/dart_contracts.py --preflight
```

Preflight needs only Python and inspects source/dependency coverage. Its JSON
explicitly says `current_dart_executed: false`; it is not a runtime test pass.
Normal execution fails if Dart is unavailable. A failed producer cannot reuse
an old JSON/JUnit result. `build/test-results/dart-pure-run.json` records SDK
version, source SHA-256 values and the verified output hash for diagnosis.

Flutter CI now runs this producer in **Production Dart contracts (no Flutter)**,
independently of the Flutter gate. The existing `junit-dart-contracts` artifact,
595 assertions and shared collector identity are retained, rather than adding
a second producer. That job uses the standalone stable Dart SDK; Flutter's
pinned and latest SDK jobs still check Flutter compatibility. This lane covers
the existing API/navigation/UI-theme model/service contracts, not painting,
plugins, native OS APIs, widget layout or screenshots. It does not pretend that
a Dart-SDK-only success proves those Flutter-specific behaviors.

Current timing audit: the Non-Dart workflow's Python pytest step took about
33 seconds; the slow portable browser invocation took 16.5 minutes in the
previous run, on top of preparation. Its browser/Web-build time must not be
attributed to Python contracts or accelerated by silently skipping assertions.
The published-page observation CLI can reuse an existing Web build; validating
unbuilt application changes still requires an appropriate build/runtime lane.


### Python oracle coverage for Dart-only changes

Non-Dart remains the full-pytest owner for Python, shared fixtures and pattern
inputs it already selects. `oracle_selection.py` uses the actual PR/push diff
to select a Python-only fallback in Flutter CI when that primary selection is
absent, including ordinary `lib/**/*.dart` and `test/**/*.dart` changes. It runs
the existing full suite without Flutter in that job, preserves outcomes and
the Python summary receipt, and provides JUnit to the existing shared collector.
Ordinary mixed Python/Dart changes have one owner; selector/workflow edits
exercise the fallback itself. First pushes without a usable base keep coverage.
Tests execute the real Non-Dart classifier for pure Dart and mixed diffs, check
exclusive ownership, and check the selected JUnit/receipt. The locked Non-Dart
workflow bytes and parent registration are unchanged.
