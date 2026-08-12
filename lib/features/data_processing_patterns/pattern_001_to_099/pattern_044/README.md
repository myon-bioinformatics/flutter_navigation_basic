# Pattern 044: BidirectionalScroll

**カテゴリ**: 案D - データ処理パターン

## 概要
双方向無限スクロール実装。

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
Get.to(() => const Pattern044View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern044Controller())));
```

## 関連パターン
- 前: Pattern 043
- 次: Pattern 045
