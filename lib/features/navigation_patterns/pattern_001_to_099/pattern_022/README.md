# Pattern 022: NamedRouteArguments

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
Named Route に引数を渡す実装。

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
Get.to(() => const Pattern022View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern022Controller())));
```

## 関連パターン
- 前: Pattern 021
- 次: Pattern 023
