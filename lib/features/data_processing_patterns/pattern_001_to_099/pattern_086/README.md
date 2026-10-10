# Pattern 086: Deduplication

Pattern 086 is the same stable first-occurrence deduplication contract already
implemented by the shared Python stdlib producer for Pattern 030. It therefore
reuses `{"operation":"distinct","values":[...]}` and the checked-in
`assets/data_processing/distinct_filter.json` catalogue example instead of
adding another Python implementation or duplicate asset.

`service.dart` selects that shared result through `JsonListAsset.load()`, and
`view.dart` configures `ProcessedListExample`. The generated message model and
GetX controller are removed. The old internal `run()` / message-result contract
is replaced by loaded values; no GetX registration or binding is needed.

This view demonstrates a Python-produced catalogue example. It does not claim
that every Flutter target already embeds Python or performs arbitrary-input
runtime deduplication; packaging/runtime bridging remains a separately measured
step.

```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const Pattern086View()),
);
```

The distinct contract, generation/check command, malformed-input behavior and
type-sensitive identity rules are documented in `docs/list-selection.md`.
The shared Flutter suite
`test/features/data_processing_patterns/pattern_001_to_099/filter_conditions_test.dart`
covers 030 and 086 against the same result boundary so this reuse cannot silently
drift into a second implementation.
