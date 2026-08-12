# Pattern 192: SwipeAction

**カテゴリ**: 案C - UI/テーマパターン

## 概要
スワイプアクション (右/左スワイプ) 実装。

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
Get.to(() => const Pattern192View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern192Controller())));
```

## 関連パターン
- 前: Pattern 191
- 次: Pattern 193
