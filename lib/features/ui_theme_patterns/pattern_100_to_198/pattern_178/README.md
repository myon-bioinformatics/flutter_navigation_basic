# Pattern 178: MergeSemantics

**カテゴリ**: 案C - UI/テーマパターン

## 概要
MergeSemantics による意味合の統合。

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
Get.to(() => const Pattern178View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern178Controller())));
```

## 関連パターン
- 前: Pattern 177
- 次: Pattern 179
