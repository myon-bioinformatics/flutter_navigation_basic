# Now Timeline: generated IANA zone table

The app bundles `assets/time/zone_table.json` and loads it before `runApp` in
both entrypoints. This replaces the hand-written London/New York DST rules.
Initialization failures are reported through `FlutterError` with asset context
and a stack trace, then rethrown; no guessed timezone fallback is installed.

The supported UTC window is **[2000-01-01, 2038-01-01)**. Conversion methods on
`IanaTimeRules` (`offsetMinutesAtUtc`, `toLocal`, `isDst`, and
`localWallTimeToUtc`) throw `RangeError` outside that window. For example,
**New York at 2040-07-01T12:00Z is rejected**, rather than silently converted
with the final winter offset. The diagnostic `lookupAtUtc` API retains its
endpoint state plus `outsideTable: true`; this state is not an extrapolated
IANA result and must not be used to schedule outside the window.

The asset contains 25 representative zones for the planned region picker.
This PR keeps the existing product selection at Tokyo, London, and New York;
adding the other zones to the picker belongs to a separate task.

## Regeneration and drift checks

The generator uses Python's standard-library `zoneinfo` and the host's IANA
TZPATH. No runtime Python dependency or pinned pip tzdata is introduced.

```sh
python3 tool/time/generate_zone_table.py          # regenerate deliberately
python3 tool/time/generate_zone_table.py --check  # compare committed content
```

`--check` compares all asset fields except the advisory `tzdata_version`
release label. A release-only difference emits a warning and succeeds when
all transitions and other fields match. A changed transition, window, region,
schema, or source still fails. Generation fails if the IANA release cannot
be determined from `tzdata.zi`; the committed asset must also retain a nonempty
release label. The asset's 2026c label records its generation source, not a
promise that every developer or CI host has that release installed. To reproduce
that exact provenance, point `PYTHONTZPATH` at a compiled 2026c directory with
its `tzdata.zi` marker before starting Python.

CI's Non-Dart lane installs system tzdata and performs this check. The Flutter
workflow is `.github/workflows/dart.yml`: it has no event path exclusion and
its classifier selects Flutter for `assets/*`, including asset-only updates.
The core suite includes `test/now_timeline`, so all generated transition
boundaries run. Python workflow tests parse YAML and execute both real path
classifiers against an asset-only diff; browser E2E selection stays automatic.
