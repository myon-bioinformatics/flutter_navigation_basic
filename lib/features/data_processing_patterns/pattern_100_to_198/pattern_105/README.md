# Pattern 105: DateConvert

## 責務と実装範囲
- Python: `tool/python/conversion_patterns.py` の `date` が処理を担当（`YYYY-MM-DD` と `YYYYMMDD` の暦日変換）。
- テスト: `tool/python/tests/test_conversion_patterns.py`。契約は `docs/data-processing-conversion-103-110.md`。
- Flutter: `/screen105` は共通の `ConversionPatternLinks` で、実装・テスト・契約への GitHub リンクを表示・コピーできる。
- 旧カタログの `view.dart` は、どの route からも使われていなかったため削除した。旧 Controller・Service・Model はない。

**対応状況: 限定実装。** Python の処理は実装済みだが、Flutter 画面からの変換実行は未接続。

## 関連パターン
- 前: Pattern 104
- 次: Pattern 106
