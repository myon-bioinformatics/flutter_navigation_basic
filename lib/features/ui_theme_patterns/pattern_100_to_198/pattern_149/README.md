# Pattern 149: AdaptiveFont

**カテゴリ**: 案C - UI/テーマパターン

## 概要
画面サイズに応じたフォントサイズ調整。

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
Get.to(() => const Pattern149View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern149Controller())));
```

## 関連パターン
- 前: Pattern 148
- 次: Pattern 150
