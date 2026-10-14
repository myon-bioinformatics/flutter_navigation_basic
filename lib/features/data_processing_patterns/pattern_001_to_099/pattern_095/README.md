# Pattern 095: UrlValidation

## 概要
URL バリデーション実装。

## 責務と実装範囲
- Python: `python/validation_patterns.py` の `url` が処理を担当。
- テスト: `python/tests/test_validation_patterns.py`。契約と制約は `docs/data-processing-validation-091-099.md`。
- ブラウザ: `python/validation_http.py` のローカル入力画面から実際に検証できる。
- Flutter: `/screen095` は共通の `ValidationPatternLinks` で、実装・テスト・入力画面・契約への GitHub リンクを表示・コピーできる。
- 旧カタログの `view.dart` は、どの route からも使われていなかったため削除した。旧 Controller・Service・Model はない。

**対応状況: 限定実装。** Python とローカルブラウザでは実行できるが、Flutter 画面からの検証実行は未接続。

## 関連パターン
- 前: Pattern 094
- 次: Pattern 096
