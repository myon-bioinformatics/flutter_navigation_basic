# Pattern 099: JsonPath

**カテゴリ**: 案B - API連携パターン

## 概要
JSON Path 形式でネスト値を取得。

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
Get.to(() => const Pattern099View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern099Controller())));
```

## 関連パターン
- 前: Pattern 098
- 次: Pattern 100
