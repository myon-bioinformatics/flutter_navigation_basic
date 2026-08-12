# Pattern 118: Flatten

**カテゴリ**: 案D - データ処理パターン

## 概要
ネストリストのフラット化処理。

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
Get.to(() => const Pattern118View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern118Controller())));
```

## 関連パターン
- 前: Pattern 117
- 次: Pattern 119
