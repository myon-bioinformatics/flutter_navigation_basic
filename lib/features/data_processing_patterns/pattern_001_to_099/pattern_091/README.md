# Pattern 091: ValidationBasic

**カテゴリ**: 案D - データ処理パターン

## 概要
基本的な入力バリデーション実装。

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
Get.to(() => const Pattern091View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern091Controller())));
```

## 関連パターン
- 前: Pattern 090
- 次: Pattern 092
