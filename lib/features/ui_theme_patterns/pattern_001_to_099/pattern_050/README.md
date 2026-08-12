# Pattern 050: CupertinoScaffold

**カテゴリ**: 案C - UI/テーマパターン

## 概要
CupertinoPageScaffold の実装。

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
Get.to(() => const Pattern050View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern050Controller())));
```

## 関連パターン
- 前: Pattern 049
- 次: Pattern 051
