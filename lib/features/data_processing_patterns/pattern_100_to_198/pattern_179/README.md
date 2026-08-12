# Pattern 179: InsertSorted

**カテゴリ**: 案D - データ処理パターン

## 概要
ソート順を維持した挿入処理。

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
Get.to(() => const Pattern179View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern179Controller())));
```

## 関連パターン
- 前: Pattern 178
- 次: Pattern 180
