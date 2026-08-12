# Pattern 033: NamedRouteBinding

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
Named Route と DI バインディングの連携。

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
Get.to(() => const Pattern033View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern033Controller())));
```

## 関連パターン
- 前: Pattern 032
- 次: Pattern 034
