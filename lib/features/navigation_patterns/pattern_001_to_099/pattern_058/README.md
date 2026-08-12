# Pattern 058: DeepLinkRestore

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
アプリ再起動後にディープリンクを復元。

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
Get.to(() => const Pattern058View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern058Controller())));
```

## 関連パターン
- 前: Pattern 057
- 次: Pattern 059
