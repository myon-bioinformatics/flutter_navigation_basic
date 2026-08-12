# Pattern 181: CommandPattern

**カテゴリ**: 案D - データ処理パターン

## 概要
Command パターンによる操作履歴管理。

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
Get.to(() => const Pattern181View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern181Controller())));
```

## 関連パターン
- 前: Pattern 180
- 次: Pattern 182
