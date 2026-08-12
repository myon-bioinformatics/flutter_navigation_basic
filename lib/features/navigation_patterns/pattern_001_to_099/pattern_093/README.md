# Pattern 093: KYC

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
本人確認フロー付き条件遷移。

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
Get.to(() => const Pattern093View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern093Controller())));
```

## 関連パターン
- 前: Pattern 092
- 次: Pattern 094
