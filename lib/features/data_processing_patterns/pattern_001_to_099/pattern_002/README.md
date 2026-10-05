# Pattern 002: FilterMultiple

Python stdlibの共通CLI `tool/python/filter_basic.py` が実処理を行います。
入力例 `tool/python/fixtures/filter_multiple_input.json` から生成した
`assets/data_processing/filter_multiple.json` を既存の画面で読み込みます。
この画面は生成済みの例の表示で、任意入力の実行時フィルターではありません。

`service.dart` は共有 `JsonListAsset` のパス指定だけ、`view.dart` は共有
`ProcessedListExample` の表示設定だけです。不要な `model.dart` と
`controller.dart` は削除しました。GetX登録やbindingは不要です。

```dart
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => const Pattern002View(),
));
```

CLIの条件契約・生成/検査コマンドは `docs/filter-basic.md`、共通の実処理・
エラー/再試行テストは `filter_conditions_test.dart` と
`tool/python/tests/test_filter_conditions.py` を参照してください。
