# Pattern 120: Zip

**カテゴリ**: 案D - データ処理パターン

## 概要
複数リストの Zip 結合処理。

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
Get.to(() => const Pattern120View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern120Controller())));
```

## 関連パターン
- 前: Pattern 119
- 次: Pattern 121
