# Pattern 158: ChangeNotifier

**カテゴリ**: 案D - データ処理パターン

## 概要
ChangeNotifier による状態通知実装。

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
Get.to(() => const Pattern158View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern158Controller())));
```

## 関連パターン
- 前: Pattern 157
- 次: Pattern 159
