# Pattern 175: ConfirmDialog

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
確認 Yes/No ダイアログ。

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
Get.to(() => const Pattern175View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern175Controller())));
```

## 関連パターン
- 前: Pattern 174
- 次: Pattern 176
