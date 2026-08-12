# Pattern 107: JsonSchema

**カテゴリ**: 案B - API連携パターン

## 概要
JSON Schema バリデーション (手動実装)。

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
Get.to(() => const Pattern107View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern107Controller())));
```

## 関連パターン
- 前: Pattern 106
- 次: Pattern 108
