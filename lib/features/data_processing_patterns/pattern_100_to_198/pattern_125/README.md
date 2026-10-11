# Pattern 125: FutureAny

**カテゴリ**: 案D - データ処理パターン

## 概要
Future.any による最速レスポンス取得。

## 実装先・検証
- 非同期の参照処理: `tool/javascript/future_patterns.mjs`, mode `any`
- Node標準テスト: `tool/javascript/tests/future_patterns.test.mjs`
- CLI仕様・Dartとの意味の違い: `docs/future-patterns.md`
- Flutter: `view.dart` は説明用。NodeをFlutterで直接起動するわけではない。
- 旧GetX Controller、ダミーService、message Modelは削除した。

```sh
node tool/javascript/future_patterns.mjs --input input.json
```
