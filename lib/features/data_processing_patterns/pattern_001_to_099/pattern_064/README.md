# Pattern 064: WeakRefCache

**カテゴリ**: 案D - データ処理パターン

## 概要
弱参照を使ったキャッシュ実装 (擬似)。

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
Get.to(() => const Pattern064View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern064Controller())));
```

## 関連パターン
- 前: Pattern 063
- 次: Pattern 065
