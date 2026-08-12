# Pattern 112: DataClean

**カテゴリ**: 案D - データ処理パターン

## 概要
欠損値・外れ値のクリーニング処理。

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
Get.to(() => const Pattern112View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern112Controller())));
```

## 関連パターン
- 前: Pattern 111
- 次: Pattern 113
