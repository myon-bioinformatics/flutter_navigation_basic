# Pattern 136: RateLimitError

**カテゴリ**: 案B - API連携パターン

## 概要
429 レートリミットエラーと待機。

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
Get.to(() => const Pattern136View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern136Controller())));
```

## 関連パターン
- 前: Pattern 135
- 次: Pattern 137
