# Pattern 148: Responsive3Col

**カテゴリ**: 案C - UI/テーマパターン

## 概要
レスポンシブ 3 カラムレイアウト。

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
Get.to(() => const Pattern148View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern148Controller())));
```

## 関連パターン
- 前: Pattern 147
- 次: Pattern 149
