# Pattern 197: ResponsiveImage

**カテゴリ**: 案B - API連携パターン

## 概要
画面サイズに応じた画像の切り替え表示。

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
Get.to(() => const Pattern197View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern197Controller())));
```

## 関連パターン
- 前: Pattern 196
- 次: Pattern 198
