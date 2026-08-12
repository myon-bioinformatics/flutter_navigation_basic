# Pattern 049: DeepLinkDynamic

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
動的パス付きディープリンク。

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
Get.to(() => const Pattern049View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern049Controller())));
```

## 関連パターン
- 前: Pattern 048
- 次: Pattern 050
