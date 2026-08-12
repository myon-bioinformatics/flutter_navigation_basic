# Pattern 183: MultiSelect

**カテゴリ**: 案D - データ処理パターン

## 概要
複数選択と一括操作の実装。

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
Get.to(() => const Pattern183View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern183Controller())));
```

## 関連パターン
- 前: Pattern 182
- 次: Pattern 184
