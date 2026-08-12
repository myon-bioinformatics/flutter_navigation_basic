# Pattern 135: NotFoundError

**カテゴリ**: 案B - API連携パターン

## 概要
404 エラーのカスタム処理。

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
Get.to(() => const Pattern135View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern135Controller())));
```

## 関連パターン
- 前: Pattern 134
- 次: Pattern 136
