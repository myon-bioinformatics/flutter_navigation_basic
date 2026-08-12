# Pattern 066: WriteThrough

**カテゴリ**: 案D - データ処理パターン

## 概要
Write-Through キャッシュ戦略。

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
Get.to(() => const Pattern066View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern066Controller())));
```

## 関連パターン
- 前: Pattern 065
- 次: Pattern 067
