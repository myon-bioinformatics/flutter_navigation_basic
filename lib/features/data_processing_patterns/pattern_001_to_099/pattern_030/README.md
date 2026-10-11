# Pattern 030: DistinctFilter

The existing Python stdlib producer accepts `{"operation":"distinct","values":[...]}`
and keeps the first value for each canonical JSON representation. Object key
order is ignored; arrays remain ordered and bool/int/float encodings remain
distinct. It validates input and emits the same values-list asset contract as
001/002/003. This is in-memory processing, not a constant-memory stream.

`service.dart` selects `assets/data_processing/distinct_filter.json` through
shared `JsonListAsset.load()`. `view.dart` configures shared
`ProcessedListExample`. Duplicate model/controller files are removed; the
internal `run()`/message-result contract is replaced by `load()` values.
No GetX registration is needed. The view displays a Python-generated example,
not arbitrary-input runtime deduplication in Flutter.

```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const Pattern030View()),
);
```

```sh
python -S tool/python/list_selection.py --input tool/python/fixtures/distinct_filter_input.json --output assets/data_processing/distinct_filter.json --check
```

Remove `--check` to generate. The existing shared Flutter
`filter_conditions_test.dart` covers this view as well; Python tests live in
`tool/python/tests/test_distinct_filter.py`. Pattern 086 now deliberately
reuses this exact processor/result asset because its documented responsibility
is the same deduplication contract; Pattern 113 remains a separate validation
candidate. See `docs/list-selection.md` and Issue #144.
