# Pattern 014: GroupBy

**カテゴリ**: 案D - データ処理パターン

## 概要
グループ化による分類表示。

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
Get.to(() => const Pattern014View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern014Controller())));
```

## 関連パターン
- 前: Pattern 013
- 次: Pattern 015
