# Pattern 055: HashPassword

**カテゴリ**: 案B - API連携パターン

## 概要
パスワードハッシュ化 (SHA-256 標準ライブラリ)。

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
Get.to(() => const Pattern055View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern055Controller())));
```

## 関連パターン
- 前: Pattern 054
- 次: Pattern 056
