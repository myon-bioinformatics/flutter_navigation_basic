# Pattern 047: DeepLinkAuthenticated

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
認証済みユーザー向けディープリンク。

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
Get.to(() => const Pattern047View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern047Controller())));
```

## 関連パターン
- 前: Pattern 046
- 次: Pattern 048
