# Pattern 130: StreamTransform

**カテゴリ**: 案D - データ処理パターン

## 概要
Stream の map/where/expand 変換。

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
Get.to(() => const Pattern130View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern130Controller())));
```

## 関連パターン
- 前: Pattern 129
- 次: Pattern 131
