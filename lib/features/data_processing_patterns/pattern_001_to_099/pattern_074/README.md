# Pattern 074: CacheStats2

**カテゴリ**: 案D - データ処理パターン

## 概要
キャッシュ統計情報収集。

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
Get.to(() => const Pattern074View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern074Controller())));
```

## 関連パターン
- 前: Pattern 073
- 次: Pattern 075
