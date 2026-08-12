# Pattern 008: Card

**カテゴリ**: 案C - UI/テーマパターン

## 概要
Card ウィジェットのスタイルバリエーション。

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
Get.to(() => const Pattern008View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern008Controller())));
```

## 関連パターン
- 前: Pattern 007
- 次: Pattern 009
