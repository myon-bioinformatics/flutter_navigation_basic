# Pattern 146: CustomScroll

**カテゴリ**: 案C - UI/テーマパターン

## 概要
CustomScrollView と Sliver の組み合わせ。

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
Get.to(() => const Pattern146View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern146Controller())));
```

## 関連パターン
- 前: Pattern 145
- 次: Pattern 147
