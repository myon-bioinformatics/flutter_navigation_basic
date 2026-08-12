# Pattern 028: SearchBar

**カテゴリ**: 案C - UI/テーマパターン

## 概要
M3 SearchBar の実装。

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
Get.to(() => const Pattern028View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern028Controller())));
```

## 関連パターン
- 前: Pattern 027
- 次: Pattern 029
