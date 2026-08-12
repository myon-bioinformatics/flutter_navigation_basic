# Pattern 056: AdaptiveWidget

**カテゴリ**: 案C - UI/テーマパターン

## 概要
プラットフォームに応じた Adaptive ウィジェット。

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
Get.to(() => const Pattern056View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern056Controller())));
```

## 関連パターン
- 前: Pattern 055
- 次: Pattern 057
