# Pattern 123: FutureError

**カテゴリ**: 案D - データ処理パターン

## 概要
Future エラーハンドリング実装。

## 実装先・検証
- 非同期の参照処理: `javascript/future_patterns.mjs`, mode `error`
- Node標準テスト: `javascript/tests/future_patterns.test.mjs`
- CLI仕様・Dartとの意味の違い: `docs/future-patterns.md`
- Flutter: `view.dart` は説明用。NodeをFlutterで直接起動するわけではない。
- 旧GetX Controller、ダミーService、message Modelは削除した。

```sh
node javascript/future_patterns.mjs --input input.json
```
