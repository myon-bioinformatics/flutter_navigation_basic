# Pattern 035: VirtualList

## 責務と実装範囲
- JavaScript: `javascript/interaction_patterns.mjs` の `virtualWindow` が独立処理を担当。
- Dart: `view.dart` は説明表示のみ。旧GetXの固定成功実行は撤去。
- 旧Controller・Service・Modelと旧Dartテストは削除済み。
- 残課題: 実DOM表示・スクロール未接続。

**対応状況: 限定実装。** 独立処理は実装済みだが、Flutter画面の完成機能としては扱わない。
