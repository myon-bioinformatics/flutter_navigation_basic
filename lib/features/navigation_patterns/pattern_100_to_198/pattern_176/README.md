# Pattern 176: FormDialog

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
フォーム入力ダイアログ。

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
Get.to(() => const Pattern176View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern176Controller())));
```

## 関連パターン
- 前: Pattern 175
- 次: Pattern 177
