# Pattern 132: StreamDebounce

**カテゴリ**: 案D - データ処理パターン

## 概要
Stream のデバウンス処理。

## 実装先と検証
- Node.js標準機能のみの参照CLI: `tool/javascript/stream_patterns.mjs` の `debounce`
- テスト: `tool/javascript/tests/stream_patterns.test.mjs`
- 契約とDart Streamとの違い: `docs/stream-patterns.md`
- Flutter `view.dart` は説明画面であり、Nodeへの実行連携は未接続。
- 旧GetX Controller、ダミーService、message Modelは削除。

```sh
node tool/javascript/stream_patterns.mjs --input input.json
```
