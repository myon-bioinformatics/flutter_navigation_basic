# Pattern 152: IOSStatusBar

**カテゴリ**: 案C - UI/テーマパターン

## 概要
iOS ステータスバーの色制御。

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
Get.to(() => const Pattern152View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern152Controller())));
```

## 関連パターン
- 前: Pattern 151
- 次: Pattern 153
