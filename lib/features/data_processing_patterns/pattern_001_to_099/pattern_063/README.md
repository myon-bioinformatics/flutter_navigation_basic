# Pattern 063: TtlCache

**カテゴリ**: 案D - データ処理パターン

## 概要
TTL 付きキャッシュ実装。

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
Get.to(() => const Pattern063View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern063Controller())));
```

## 関連パターン
- 前: Pattern 062
- 次: Pattern 064
