# Pattern 107: UnitConvert

## 責務と実装範囲
- Python: `tool/python/conversion_patterns.py` の `unit` が処理を担当（長さ（m/km/cm）・重量（kg/g）の変換。overflow/underflow は拒否）。
- テスト: `tool/python/tests/test_conversion_patterns.py`。契約は `docs/data-processing-conversion-103-110.md`。
- Flutter: `/screen107` は共通の `ConversionPatternLinks` で、実装・テスト・契約への GitHub リンクを表示・コピーできる。
- 旧カタログの `view.dart` は、どの route からも使われていなかったため削除した。旧 Controller・Service・Model はない。

**対応状況: 限定実装。** Python の処理は実装済みだが、Flutter 画面からの変換実行は未接続。

## 関連パターン
- 前: Pattern 106
- 次: Pattern 108
