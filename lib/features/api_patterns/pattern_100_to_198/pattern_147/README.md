# Pattern 147: RetryBudget

**カテゴリ**: 案B - API連携パターン

## 概要
リトライ予算 (最大試行回数) 管理。

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
Get.to(() => const Pattern147View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern147Controller())));
```

## 関連パターン
- 前: Pattern 146
- 次: Pattern 148
