# Pattern 134: AuthError

**カテゴリ**: 案B - API連携パターン

## 概要
401/403 認証エラーの自動処理。

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
Get.to(() => const Pattern134View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern134Controller())));
```

## 関連パターン
- 前: Pattern 133
- 次: Pattern 135
