# Pattern 178: MoveToBottom

アイテムをリスト末尾に移動。

## 実装と検証
- Python標準ライブラリの独立CLI: `tool/python/workflow_patterns.py` operation `move_bottom`
- pytest: `tool/python/tests/test_workflow_patterns.py`
- 境界仕様: `docs/workflow-patterns.md`
- 元のServiceは100ms待つ成功ダミーだったため削除した。
- Flutter `view.dart` はナビゲーション互換の説明画面であり、CLI実行は未接続。
- DBや分散処理などの本番システムの互換実装ではない。
