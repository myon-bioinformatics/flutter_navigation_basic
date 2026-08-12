# Pattern 048: FlatList

**カテゴリ**: 案D - データ処理パターン

## 概要
フラット化した階層リスト表示。

## ファイル構成
| ファイル | 役割 |
|---|---|
| `view.dart` | UI コンポーネント |
| `controller.dart` | ビジネスロジック (GetX Controller) |
| `service.dart` | サービス層 |
| `model.dart` | データモデル |
| `README.md` | 本ドキュメント |
| `test.dart` | テストコード |

## 使用例
```dart
// GetX での画面遷移
Get.to(() => const Pattern048View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern048Controller())));
```

## 関連パターン
- 前: Pattern 047
- 次: Pattern 049
