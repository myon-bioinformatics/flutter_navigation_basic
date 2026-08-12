# Pattern 102: SanitizeInput

**カテゴリ**: 案D - データ処理パターン

## 概要
XSS/SQLインジェクション防止の入力サニタイズ。

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
Get.to(() => const Pattern102View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern102Controller())));
```

## 関連パターン
- 前: Pattern 101
- 次: Pattern 103
