# Pattern 004: PushWithResult

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
遷移先から結果を受け取る Push & Return値。

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
Get.to(() => const Pattern004View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern004Controller())));
```

## 関連パターン
- 前: Pattern 003
- 次: Pattern 005
