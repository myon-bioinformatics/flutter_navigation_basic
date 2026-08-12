# Pattern 032: CursorPagination

**カテゴリ**: 案D - データ処理パターン

## 概要
カーソル方式のページネーション。

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
Get.to(() => const Pattern032View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern032Controller())));
```

## 関連パターン
- 前: Pattern 031
- 次: Pattern 033
