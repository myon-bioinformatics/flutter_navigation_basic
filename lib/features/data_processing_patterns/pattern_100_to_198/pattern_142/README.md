# Pattern 142: ParallelMap

**カテゴリ**: 案D - データ処理パターン

## 概要
リストの並列 map 処理。

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
Get.to(() => const Pattern142View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern142Controller())));
```

## 関連パターン
- 前: Pattern 141
- 次: Pattern 143
