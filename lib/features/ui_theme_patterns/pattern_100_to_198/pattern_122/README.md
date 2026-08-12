# Pattern 122: BreakPoint

**カテゴリ**: 案C - UI/テーマパターン

## 概要
ブレークポイント定義とウィジェット切り替え。

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
Get.to(() => const Pattern122View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern122Controller())));
```

## 関連パターン
- 前: Pattern 121
- 次: Pattern 123
