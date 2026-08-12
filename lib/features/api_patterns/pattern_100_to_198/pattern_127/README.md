# Pattern 127: ErrorMapping

**カテゴリ**: 案B - API連携パターン

## 概要
HTTP ステータスコードをカスタム例外へ変換。

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
Get.to(() => const Pattern127View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern127Controller())));
```

## 関連パターン
- 前: Pattern 126
- 次: Pattern 128
