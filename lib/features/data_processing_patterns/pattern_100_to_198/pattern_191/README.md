# Pattern 191: Saga

**カテゴリ**: 案D - データ処理パターン

## 概要
Saga パターンによる分散トランザクション (擬似)。

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
Get.to(() => const Pattern191View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern191Controller())));
```

## 関連パターン
- 前: Pattern 190
- 次: Pattern 192
