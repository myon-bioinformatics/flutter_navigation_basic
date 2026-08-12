# Pattern 108: BackInterceptor

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
バック操作を横取りして処理を挟む。

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
Get.to(() => const Pattern108View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern108Controller())));
```

## 関連パターン
- 前: Pattern 107
- 次: Pattern 109
