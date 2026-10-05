# Pattern 001: FilterBasic

**カテゴリ**: 案D - データ処理パターン

## 概要
Pythonで生成した単一条件フィルター結果をFlutterで読み込んで表示するカタログ例。

実際のフィルター処理は `tool/python/filter_basic.py` が担当し、
Flutter側は共有 `JsonListAsset` / `ProcessedListExample` を使う。
任意入力をFlutter実行時にフィルタリングする機能ではない。

## ファイル構成
| ファイル | 役割 |
|---|---|
| `view.dart` | 共有表示境界の設定 |
| `service.dart` | 生成済みasset pathの指定 |
| `README.md` | 本ドキュメント |

pattern固有の `model.dart` / `controller.dart` は不要になったため削除済み。

## 使用例
```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const Pattern001View()),
);
```

## 関連パターン
- 次: Pattern 002
