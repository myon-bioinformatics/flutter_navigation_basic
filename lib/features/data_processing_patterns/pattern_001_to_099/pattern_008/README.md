# Pattern 008: SearchHistory

**カテゴリ**: 案D - データ処理パターン

## 概要
検索履歴の保存と表示。

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
Get.to(() => const Pattern008View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern008Controller())));
```

## 関連パターン
- 前: Pattern 007
- 次: Pattern 009
