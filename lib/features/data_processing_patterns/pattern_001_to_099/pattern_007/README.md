# Pattern 007: SearchHighlight

## 責務と機能契約
- Python: `python/search_patterns.py` の `highlight` が担当。
- 実装範囲: 正規化した文字列の一致判定のみ。ハイライト範囲・表示は未実装。
- 検証: `python/tests/test_search_patterns.py` の正常・異常系。
- Dart: `view.dart` は限定実装の説明表示のみ。Python CLIの呼び出しと結果表示は未接続。
- 固定成功を返す旧GetX Controller・Service・Modelと旧Dartテストは削除済み。

**対応状況: 限定実装**。Flutterから操作できる完成機能としては数えない。
