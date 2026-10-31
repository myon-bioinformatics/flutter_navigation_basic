# Dart output, Python decisions, Flutter interaction evidence

The migration starts from main `39620c0b206e4ce05cc078bfaea7ae5b359de4e0`.
The externally supplied `/workspace/flutter_test_triage.md` was not available in
this workspace. The inventory below was independently checked against source.

| Previous suites | Change | Replacement evidence |
| --- | --- | --- |
| 594 API/navigation/UI-theme files, 1,189 test declarations | Removed repetitive model/stub suites | One Dart producer executes all 594 real model classes and 592 placeholder services; Python emits 595 JUnit cases including inventory |
| Route names, screens data, display assets, photo fixtures (4 files, 14 declarations) | Removed integrity suites | Thin Dart metadata export preserves real constants and decoding; Python validates routes, 198 screens, 11 locale maps, PNG/JPEG fixture structure |
| Widget/navigation/clipboard/image codecs/localized UI | Retained | Flutter and browser tests continue to exercise the actual platform behavior |
| Remaining domain calculations and data-processing patterns | Retained | Existing shared JSON oracles remain; no mass deletion of formula or platform coverage |

`flutter analyze` alone does not prove serialization or runtime behavior. The
replacement always executes production Dart first. Python expectations are
independent; they are not extracted from production method bodies. API 001/002
retain their distinct body/echo/default/missing-optional checks. Their real HTTP
services are not invoked; the old suites also only tested their models.
Placeholder services remain placeholders, not evidence of 592 working features.

No writer for the removed generated suites was found among the repository's
tracked Dart/Python/shell tooling. The new explicit producer generator is checked
in CI so an omitted model cannot silently disappear from coverage.

## Export and investigate

Run from the repository root after `flutter pub get`:

```sh
python3 -S python/generate_pattern_contracts.py --check
dart run build_tools/export_pattern_contracts.dart build/test-results/pattern-contracts.json
python3 -S python/pattern_contracts.py build/test-results/pattern-contracts.json --junit build/test-results/pattern-contracts.xml
flutter test test/contracts/metadata_export_test.dart
python3 -S python/metadata_contracts.py build/test-results/metadata-contracts.json
uv run --locked --project python pytest python/tests/test_pattern_contracts.py python/tests/test_metadata_contracts.py python/tests/test_header_contracts.py
```

To inspect a single decision, open `cases["api/001"]` in the pattern JSON, edit a
copy, and run the Python command against that copy. `encoded`, `restored`,
`defaults`, `missingOptional`, and `service` are observed Dart results. Runtime
exceptions are recorded as failures. Mutation tests verify rejection of missing
cases, changed round trips/defaults, empty stub results, and exceptions.

The pinned Flutter gate preserves `junit-dart-contracts` (JSON + Python JUnit).
Core shards preserve `metadata-contracts.json` alongside Flutter raw JSONL and
JUnit. The shared JUnit collector expects the extra report and still fails for
missing reports or native failures. PR #175 adds a generated Flutter smoke suite alongside these independent
contracts. Pattern shards run 594 model round trips, 592 service calls, the
restored API 001/002 dedicated model tests, and remaining data-processing tests.
Service failures retain pattern ID, exception summary and stack, and all calls
finish before the aggregate assertion. Generator/test-only changes also select
the Flutter and pattern lanes.

Shard 0 additionally runs `check_pattern_smoke_mutations.py`: it temporarily
changes real UI-theme service 147 to throw, then to return an empty message.
Each run must exit 1 with one actual test failure and the pattern ID plus cause
in converted JUnit; compilation errors or an unexpectedly passing suite fail
the regression check. Source bytes are restored in `finally`. The
`pattern-smoke-mutation-evidence` artifact retains expected failure JSONL, logs,
JUnit and receipts separately from normal `junit-*` collection. Normal shards
still fail on real failures and the shared collector requires every report. Catalogue production sources remain analyzed.

## Header acceptance

Every reachable page uses `StandardPageHeader`, directly or via its compatible
`CustomAppBar` wrapper. The first row contains title, Home, session favorite and
Menu; Back appears when navigation can pop. Page-specific actions occupy a
separate horizontally scrollable second row. Hub search remains below them.
Language and the session text clipboard are accessible from the shared menu.
Photo Studio retains its dirty indicator, keyboard shortcuts, and leave guard.

Titles include an emoji; selectors use `shared-header-*` semantic identifiers,
not title strings, translations, or the presence of emoji. Favorites are an
in-memory prototype and reset on reload.

`e2e/tests/shared_header.spec.ts` exercises 12 representative routes on the
existing five-browser matrix (desktop Chromium/Firefox/WebKit and mobile browser
emulations). It saves screenshots and measured `header-contract.json` files.
`python/header_contracts.py` checks visible geometry, common-row alignment,
secondary-row separation, and emoji. Button toggling and menu opening are tested
in the real browser. Emulation does not claim physical Android/iPhone evidence.
The existing Diagnostics workflow additionally validates screenshots and
canonical gh_identity provenance with the pinned browser-test-kit validators.

The pre-existing five `generic_screen_test` failures reproduce on the baseline.
The test harness now preloads the production catalogue outside Flutter's fake
clock, preventing cached asynchronous asset work from leaking across test zones.
The injected failure/retry test still performs the actual asynchronous UI flow.

The reported baseline 255 seconds / 125 seconds was not measured here and is not
claimed as a verified speedup. Compare like-for-like CI artifacts after merging;
this change removes repeated suite startup and batches only placeholder delays.
