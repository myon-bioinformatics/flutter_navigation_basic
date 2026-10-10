# Pattern 116: Pipeline

**カテゴリ**: 案D - データ処理パターン

## 概要
データ変換パイプライン実装。

## 実装と検証
- 計算処理: `tool/python/collection_transform.py` の `pipeline` 操作
- Python回帰テスト: `tool/python/tests/test_collection_transform.py`
- CLI仕様: `docs/collection-transform.md`
- UI: `view.dart` はFlutterの情報表示境界。Pythonプロセスの直接呼び出しは行わない。
- 旧GetX Controller／ダミーService／message Modelは削除済み。

## CLIの起動例
```sh
python -S tool/python/collection_transform.py --input input.json
```

入力JSONに `"operation": "pipeline"` と `"values"` を含める。
必要な追加フィールドはCLI仕様を参照すること。
Flutterでの実行やデータ表示まで実装済みと誤認しないこと。
