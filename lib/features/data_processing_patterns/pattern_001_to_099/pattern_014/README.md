# Pattern 014: GroupBy

## 責務と実装状態
- Python: `python/collection_query_patterns.py` の `group_by` で独立した実処理を実装。
- テスト: `python/tests/test_collection_query_patterns.py` で処理契約を検証。
- Dart: `view.dart` は説明画面のみ。FlutterからPythonを呼び出す経路は未接続。
- 旧Controller・Service・Modelと固定成功文言を検証する旧テストは削除済み。

**対応状況: 限定実装。** 実行可能なPython処理はあるが、画面操作と結果表示は未実装。
