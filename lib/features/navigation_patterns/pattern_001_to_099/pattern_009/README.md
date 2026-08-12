# Pattern 009: PushWithArguments

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
引数を渡して画面遷移する。

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
Get.to(() => const Pattern009View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern009Controller())));
```

## 関連パターン
- 前: Pattern 008
- 次: Pattern 010
