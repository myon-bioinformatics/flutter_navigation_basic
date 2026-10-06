# Pattern 113: DataDeduplicate

Pattern 113 treats “データ重複排除バリデーション” as a validation/reporting
responsibility, not as another implementation of Pattern 030/086 stable
deduplication.

The shared stdlib-only `tool/python/list_selection.py` command accepts
`{"operation":"deduplicate_report","values":[...]}`. It applies the same
canonical JSON identity rules used by distinct selection, then emits one report
record with `input_count`, `unique_count`, `duplicate_count` and
`has_duplicates`. Duplicate presence is valid report data; malformed input is
still a CLI error. The operation does not mutate or return the source list.

`service.dart` only selects the checked-in
`assets/data_processing/deduplicate_report.json` example and `view.dart`
uses the existing `ProcessedListExample` loading/error/retry boundary. The
generated message model and GetX controller are removed. This remains a
Python-produced catalogue example: it does not claim that every Flutter target
already bundles or launches Python for arbitrary runtime inputs.

```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const Pattern113View()),
);
```

Generation/check commands and identity rules are documented in
`docs/list-selection.md`. The focused Flutter test verifies the real report
asset and the shared UI boundary without reintroducing deduplication logic in
Dart.
