# Pattern 104: TypeCoercion

## 責務と実装範囲
- Python: `tool/python/conversion_patterns.py` の `coerce` が処理を担当（int / float / bool の明示的で厳格な変換）。
- テスト: `tool/python/tests/test_conversion_patterns.py`。契約は `docs/data-processing-conversion-103-110.md`。
- Flutter: `/screen104` は共通の `ConversionPatternLinks` で、実装・テスト・契約への GitHub リンクを表示・コピーできる。
- `view.dart` は旧カタログの説明表示で、番号付きルートからは使われていない。旧 Controller・Service・Model はない。

**対応状況: 限定実装。** Python の処理は実装済みだが、Flutter 画面からの変換実行は未接続。

## 関連パターン
- 前: Pattern 103
- 次: Pattern 105
