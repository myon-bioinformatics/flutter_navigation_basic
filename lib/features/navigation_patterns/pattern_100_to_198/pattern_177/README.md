# Pattern 177: SearchDelegate

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
SearchDelegate による検索画面。

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
Get.to(() => const Pattern177View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern177Controller())));
```

## 関連パターン
- 前: Pattern 176
- 次: Pattern 178
