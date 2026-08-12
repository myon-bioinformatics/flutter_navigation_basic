# Pattern 045: SessionCookie

**カテゴリ**: 案B - API連携パターン

## 概要
Cookie セッション管理 (擬似実装)。

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
Get.to(() => const Pattern045View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern045Controller())));
```

## 関連パターン
- 前: Pattern 044
- 次: Pattern 046
