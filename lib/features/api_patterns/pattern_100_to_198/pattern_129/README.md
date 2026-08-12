# Pattern 129: ErrorBoundary

**カテゴリ**: 案B - API連携パターン

## 概要
ウィジェットレベルのエラーバウンダリ。

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
Get.to(() => const Pattern129View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern129Controller())));
```

## 関連パターン
- 前: Pattern 128
- 次: Pattern 130
