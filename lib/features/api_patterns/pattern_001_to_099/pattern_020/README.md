# Pattern 020: ConditionalGet

**カテゴリ**: 案B - API連携パターン

## 概要
If-Modified-Since 付き条件付き GET。

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
Get.to(() => const Pattern020View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern020Controller())));
```

## 関連パターン
- 前: Pattern 019
- 次: Pattern 021
