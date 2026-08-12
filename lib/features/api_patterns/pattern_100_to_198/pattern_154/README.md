# Pattern 154: CacheControl

**カテゴリ**: 案B - API連携パターン

## 概要
Cache-Control ヘッダーのパースと適用。

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
Get.to(() => const Pattern154View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern154Controller())));
```

## 関連パターン
- 前: Pattern 153
- 次: Pattern 155
