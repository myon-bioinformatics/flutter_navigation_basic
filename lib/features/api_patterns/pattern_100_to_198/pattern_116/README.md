# Pattern 116: JsonStringify

**カテゴリ**: 案B - API連携パターン

## 概要
Dart 値を JSON 文字列にシリアライズ。

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
Get.to(() => const Pattern116View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern116Controller())));
```

## 関連パターン
- 前: Pattern 115
- 次: Pattern 117
