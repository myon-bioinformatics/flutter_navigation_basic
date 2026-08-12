# Pattern 011: JsonList

**カテゴリ**: 案B - API連携パターン

## 概要
JSON 配列のパースと一覧表示。

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
Get.to(() => const Pattern011View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern011Controller())));
```

## 関連パターン
- 前: Pattern 010
- 次: Pattern 012
