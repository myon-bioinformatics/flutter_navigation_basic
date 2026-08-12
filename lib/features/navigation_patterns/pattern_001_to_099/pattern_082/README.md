# Pattern 082: RoleBasedNav

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
ロールに応じて表示画面を切り替え。

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
Get.to(() => const Pattern082View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern082Controller())));
```

## 関連パターン
- 前: Pattern 081
- 次: Pattern 083
