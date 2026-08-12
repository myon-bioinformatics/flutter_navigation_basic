# Pattern 159: ValueNotifier

**カテゴリ**: 案D - データ処理パターン

## 概要
ValueNotifier の基本実装。

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
Get.to(() => const Pattern159View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern159Controller())));
```

## 関連パターン
- 前: Pattern 158
- 次: Pattern 160
