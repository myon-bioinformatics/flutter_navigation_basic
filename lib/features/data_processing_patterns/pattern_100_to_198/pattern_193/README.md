# Pattern 193: EventSourcing

**カテゴリ**: 案D - データ処理パターン

## 概要
Event Sourcing パターンの擬似実装。

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
Get.to(() => const Pattern193View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern193Controller())));
```

## 関連パターン
- 前: Pattern 192
- 次: Pattern 194
