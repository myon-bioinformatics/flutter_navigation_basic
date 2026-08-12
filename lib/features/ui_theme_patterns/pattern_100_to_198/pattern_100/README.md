# Pattern 100: AMOLED

**カテゴリ**: 案C - UI/テーマパターン

## 概要
AMOLED 向け純黒ダークモード実装。

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
Get.to(() => const Pattern100View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern100Controller())));
```

## 関連パターン
- 前: Pattern 099
- 次: Pattern 101
