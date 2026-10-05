# Pattern 001: FilterBasic

Python stdlib processes supplied JSON and generates
`assets/data_processing/filter_basic.json`. This catalogue view displays that
result; it does not filter arbitrary input at Flutter runtime.

`service.dart` selects the asset using shared `JsonListAsset.load()`.
`view.dart` configures shared `ProcessedListExample` loading/result/error/retry
state. The obsolete message-only model and GetX controller were removed.
The internal `run()`/message-result contract is intentionally replaced by
`load()` values, as in patterns 002/003. No GetX registration or binding is needed.

```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const Pattern001View()),
);
```

Processing and generation commands: `docs/filter-basic.md`.
The shared Flutter suite is
`test/features/data_processing_patterns/pattern_001_to_099/filter_conditions_test.dart`.
It tests the real asset, malformed/missing data and UI loading/error/retry/disposal
without global controller registration. Related examples: 002 and 003.
