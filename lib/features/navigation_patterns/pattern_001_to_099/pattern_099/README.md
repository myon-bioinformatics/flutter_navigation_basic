# Pattern 099: ThemeConditional

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
テーマに応じた条件遷移。

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
Get.to(() => const Pattern099View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern099Controller())));
```

## 関連パターン
- 前: Pattern 098
- 次: Pattern 100
