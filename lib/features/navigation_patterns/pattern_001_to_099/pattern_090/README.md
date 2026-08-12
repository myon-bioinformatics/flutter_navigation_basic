# Pattern 090: SubscriptionGuard

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
サブスクリプション確認付き遷移。

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
Get.to(() => const Pattern090View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern090Controller())));
```

## 関連パターン
- 前: Pattern 089
- 次: Pattern 091
