# Pattern 093: JsonList

**カテゴリ**: 案B - API連携パターン

## 概要
JSON 配列の Dart List への変換。

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
Get.to(() => const Pattern093View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern093Controller())));
```

## 関連パターン
- 前: Pattern 092
- 次: Pattern 094
