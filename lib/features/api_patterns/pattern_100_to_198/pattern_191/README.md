# Pattern 191: ImageEmbed

**カテゴリ**: 案B - API連携パターン

## 概要
ネットワーク画像の埋め込み表示。

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
Get.to(() => const Pattern191View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern191Controller())));
```

## 関連パターン
- 前: Pattern 190
- 次: Pattern 192
