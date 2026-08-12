# Pattern 190: QRScan

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
QR スキャン結果→遷移先決定フロー。

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
Get.to(() => const Pattern190View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern190Controller())));
```

## 関連パターン
- 前: Pattern 189
- 次: Pattern 191
