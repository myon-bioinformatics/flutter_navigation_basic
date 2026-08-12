# Pattern 184: DragReorder

**カテゴリ**: 案D - データ処理パターン

## 概要
長押し+ドラッグによる並び替え。

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
Get.to(() => const Pattern184View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern184Controller())));
```

## 関連パターン
- 前: Pattern 183
- 次: Pattern 185
