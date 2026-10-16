# Pattern 023: Stemming

## 責務と機能契約
- Python: `python/search_patterns.py` の `stem` が担当。
- 実装範囲: 限定的な英語接尾辞の除去。言語学的な完全ステミングではない。
- 検証: `python/tests/test_search_patterns.py` の正常・異常系。
- Dart: `view.dart` は限定実装の説明表示のみ。Python CLIの呼び出しと結果表示は未接続。
- 固定成功を返す旧GetX Controller・Service・Modelと旧Dartテストは削除済み。

**対応状況: 限定実装**。Flutterから操作できる完成機能としては数えない。
