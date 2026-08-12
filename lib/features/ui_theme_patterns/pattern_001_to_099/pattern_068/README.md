# Pattern 068: MultiTheme

**カテゴリ**: 案C - UI/テーマパターン

## 概要
複数テーマ選択 UI の実装。

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
Get.to(() => const Pattern068View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern068Controller())));
```

## 関連パターン
- 前: Pattern 067
- 次: Pattern 069
