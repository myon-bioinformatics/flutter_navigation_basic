# Pattern 025: TfIdf

## 責務と実装範囲
- Python: `tool/python/scoring_heap_patterns.py` の `tfidf` が独立処理を担当。
- Dart: `view.dart` は説明表示のみ。旧GetXの固定成功実行は撤去。
- 旧Controller・Service・Modelと旧Dartテストは削除済み。
- 残課題: Flutterからの実行未接続。

**対応状況: 限定実装。** 独立処理は実装済みだが、Flutter画面の完成機能としては扱わない。
