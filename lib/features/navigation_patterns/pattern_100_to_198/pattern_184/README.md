# Pattern 184: ProfileSetup

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
初回プロフィール設定ウィザード。

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
Get.to(() => const Pattern184View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern184Controller())));
```

## 関連パターン
- 前: Pattern 183
- 次: Pattern 185
