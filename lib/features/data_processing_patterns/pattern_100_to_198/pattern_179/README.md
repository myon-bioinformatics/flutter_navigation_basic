# Pattern 179: InsertSorted

ソート順を維持した挿入処理。

## 実装と検証
- Python標準ライブラリの独立CLI: `tool/python/workflow_patterns.py` operation `insert_sorted`
- pytest: `tool/python/tests/test_workflow_patterns.py`
- 境界仕様: `docs/workflow-patterns.md`
- 元のServiceは100ms待つ成功ダミーだったため削除した。
- Flutter `view.dart` はナビゲーション互換の説明画面であり、CLI実行は未接続。
- DBや分散処理などの本番システムの互換実装ではない。
