# Pattern 111: DataEnrich

**カテゴリ**: 案D - データ処理パターン

## 概要
外部データによるデータ補完。

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
Get.to(() => const Pattern111View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern111Controller())));
```

## 関連パターン
- 前: Pattern 110
- 次: Pattern 112
