# Pattern 112: TonalPalette

**カテゴリ**: 案C - UI/テーマパターン

## 概要
Tonal Palette によるカラー生成。

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
Get.to(() => const Pattern112View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern112Controller())));
```

## 関連パターン
- 前: Pattern 111
- 次: Pattern 113
