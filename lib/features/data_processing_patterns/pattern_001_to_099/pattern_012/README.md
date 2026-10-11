# Pattern 012: SortCustom

## 機能と責務
- Python: `tool/python/collection_query_patterns.py` の `custom_sort` が実際の並べ替えを担当。
- Pythonテスト: `tool/python/tests/test_collection_query_patterns.py` がソートの契約を検証。
- Dart: `view.dart` は画面の説明と利用可能な範囲を表示するだけ。FlutterからPython CLIへの実行接続は未実装。
- 旧Controller・Service・Modelと、固定成功文字列を検証していた旧Dartテストは削除済み。

## 対応状況
**限定実装**。Pythonでのソート処理は実装済みだが、Flutter画面からの実行と結果表示は未接続。削除したダミー実行ボタンを実機能として数えない。
