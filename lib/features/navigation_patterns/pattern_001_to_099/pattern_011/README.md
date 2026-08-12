# Pattern 011: WillPopScope

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
WillPopScope で遷移キャンセルを制御。

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
Get.to(() => const Pattern011View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern011Controller())));
```

## 関連パターン
- 前: Pattern 010
- 次: Pattern 012
