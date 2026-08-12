# Pattern 166: FullScreen

**カテゴリ**: 案C - UI/テーマパターン

## 概要
フルスクリーンモード切り替え。

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
Get.to(() => const Pattern166View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern166Controller())));
```

## 関連パターン
- 前: Pattern 165
- 次: Pattern 167
