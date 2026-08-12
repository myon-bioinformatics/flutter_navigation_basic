# Pattern 119: Partition

**カテゴリ**: 案D - データ処理パターン

## 概要
条件によるデータ分割処理。

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
Get.to(() => const Pattern119View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern119Controller())));
```

## 関連パターン
- 前: Pattern 118
- 次: Pattern 120
