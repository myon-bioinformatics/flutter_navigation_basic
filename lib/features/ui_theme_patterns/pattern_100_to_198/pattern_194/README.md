# Pattern 194: DragDrop

**カテゴリ**: 案C - UI/テーマパターン

## 概要
ドラッグ&ドロップ UI 実装。

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
Get.to(() => const Pattern194View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern194Controller())));
```

## 関連パターン
- 前: Pattern 193
- 次: Pattern 195
