# Pattern 096: ModelToJson

**カテゴリ**: 案B - API連携パターン

## 概要
Dart クラスを JSON 文字列に直列化。

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
Get.to(() => const Pattern096View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern096Controller())));
```

## 関連パターン
- 前: Pattern 095
- 次: Pattern 097
