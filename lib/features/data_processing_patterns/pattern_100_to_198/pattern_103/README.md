# Pattern 103: DataNormalize

**カテゴリ**: 案D - データ処理パターン

## 概要
データ正規化 (文字列トリム、大文字小文字統一等)。

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
Get.to(() => const Pattern103View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern103Controller())));
```

## 関連パターン
- 前: Pattern 102
- 次: Pattern 104
