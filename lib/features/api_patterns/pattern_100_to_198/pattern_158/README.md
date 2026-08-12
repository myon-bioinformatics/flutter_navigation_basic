# Pattern 158: CacheInvalidate

**カテゴリ**: 案B - API連携パターン

## 概要
手動キャッシュ無効化実装。

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
Get.to(() => const Pattern158View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern158Controller())));
```

## 関連パターン
- 前: Pattern 157
- 次: Pattern 159
