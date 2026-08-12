# Pattern 058: AdaptiveTextField

**カテゴリ**: 案C - UI/テーマパターン

## 概要
プラットフォームに応じたテキスト入力。

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
Get.to(() => const Pattern058View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern058Controller())));
```

## 関連パターン
- 前: Pattern 057
- 次: Pattern 059
