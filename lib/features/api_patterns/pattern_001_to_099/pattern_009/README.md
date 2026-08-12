# Pattern 009: JsonSerialize

**カテゴリ**: 案B - API連携パターン

## 概要
Dart オブジェクトを JSON に変換して送信。

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
Get.to(() => const Pattern009View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern009Controller())));
```

## 関連パターン
- 前: Pattern 008
- 次: Pattern 010
