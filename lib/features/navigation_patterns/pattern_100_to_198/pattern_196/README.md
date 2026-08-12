# Pattern 196: WidgetToRoute

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
ウィジェット状態をルート引数として渡す。

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
Get.to(() => const Pattern196View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern196Controller())));
```

## 関連パターン
- 前: Pattern 195
- 次: Pattern 197
