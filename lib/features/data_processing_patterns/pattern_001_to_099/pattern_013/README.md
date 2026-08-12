# Pattern 013: SortReverse

**カテゴリ**: 案D - データ処理パターン

## 概要
昇順/降順切り替えソート。

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
Get.to(() => const Pattern013View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern013Controller())));
```

## 関連パターン
- 前: Pattern 012
- 次: Pattern 014
