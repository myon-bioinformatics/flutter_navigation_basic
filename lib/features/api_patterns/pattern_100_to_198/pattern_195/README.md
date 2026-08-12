# Pattern 195: SvgEmbed

**カテゴリ**: 案B - API連携パターン

## 概要
SVG 画像の埋め込み表示 (擬似実装)。

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
Get.to(() => const Pattern195View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern195Controller())));
```

## 関連パターン
- 前: Pattern 194
- 次: Pattern 196
