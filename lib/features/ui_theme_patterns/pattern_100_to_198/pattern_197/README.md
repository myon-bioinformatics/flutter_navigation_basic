# Pattern 197: ShakeDetect

**カテゴリ**: 案C - UI/テーマパターン

## 概要
シェイクジェスチャー検出 (擬似実装)。

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
