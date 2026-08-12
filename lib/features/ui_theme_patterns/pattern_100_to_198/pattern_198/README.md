# Pattern 198: AnimatedFeedback

**カテゴリ**: 案C - UI/テーマパターン

## 概要
タップフィードバックアニメーション。

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
Get.to(() => const Pattern198View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern198Controller())));
```

## 関連パターン
- 前: Pattern 197
- 次: Pattern 198
