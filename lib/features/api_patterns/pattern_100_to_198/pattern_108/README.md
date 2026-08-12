# Pattern 108: JsonTransform

**カテゴリ**: 案B - API連携パターン

## 概要
JSON データの変換・整形処理。

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
Get.to(() => const Pattern108View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern108Controller())));
```

## 関連パターン
- 前: Pattern 107
- 次: Pattern 109
