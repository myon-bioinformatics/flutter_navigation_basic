# Pattern 125: WrapLayout

**カテゴリ**: 案C - UI/テーマパターン

## 概要
Wrap による折り返しレイアウト。

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
Get.to(() => const Pattern125View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern125Controller())));
```

## 関連パターン
- 前: Pattern 124
- 次: Pattern 126
