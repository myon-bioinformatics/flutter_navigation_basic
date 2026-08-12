# Pattern 010: NestedJson

**カテゴリ**: 案B - API連携パターン

## 概要
ネストした JSON 構造のパース。

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
Get.to(() => const Pattern010View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern010Controller())));
```

## 関連パターン
- 前: Pattern 009
- 次: Pattern 011
