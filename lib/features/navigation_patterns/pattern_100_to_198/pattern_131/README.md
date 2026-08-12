# Pattern 131: TabNestedNav

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
各タブが独自の Navigator を持つ実装。

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
Get.to(() => const Pattern131View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern131Controller())));
```

## 関連パターン
- 前: Pattern 130
- 次: Pattern 132
