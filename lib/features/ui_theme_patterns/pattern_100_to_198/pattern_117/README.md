# Pattern 117: AutoTheme

**カテゴリ**: 案C - UI/テーマパターン

## 概要
明暗自動切り替えテーマ実装。

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
Get.to(() => const Pattern117View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern117Controller())));
```

## 関連パターン
- 前: Pattern 116
- 次: Pattern 118
