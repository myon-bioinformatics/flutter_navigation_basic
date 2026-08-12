# Pattern 151: GetxState

**カテゴリ**: 案D - データ処理パターン

## 概要
GetX を使った基本的な状態管理。

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
Get.to(() => const Pattern151View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern151Controller())));
```

## 関連パターン
- 前: Pattern 150
- 次: Pattern 152
