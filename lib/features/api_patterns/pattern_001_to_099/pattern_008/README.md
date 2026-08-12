# Pattern 008: JsonParse

**カテゴリ**: 案B - API連携パターン

## 概要
レスポンス JSON を Dart オブジェクトへ変換。

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
Get.to(() => const Pattern008View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern008Controller())));
```

## 関連パターン
- 前: Pattern 007
- 次: Pattern 009
