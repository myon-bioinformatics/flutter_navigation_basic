# Pattern 001: BasicPush

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
最も基本的な画面プッシュ遷移。Navigator.push/Get.to。

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
Get.to(() => const Pattern001View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern001Controller())));
```

## 関連パターン
- 前: Pattern 001
- 次: Pattern 002
