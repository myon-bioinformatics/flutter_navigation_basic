# Pattern 018: Divider

**カテゴリ**: 案C - UI/テーマパターン

## 概要
Divider と VerticalDivider。

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
Get.to(() => const Pattern018View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern018Controller())));
```

## 関連パターン
- 前: Pattern 017
- 次: Pattern 019
