# Pattern 003: HttpPut

**カテゴリ**: 案B - API連携パターン

## 概要
リソース全体更新の PUT リクエスト。

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
Get.to(() => const Pattern003View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern003Controller())));
```

## 関連パターン
- 前: Pattern 002
- 次: Pattern 004
