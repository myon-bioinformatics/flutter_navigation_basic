# Pattern 023: NamedRouteResult

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
Named Route の遷移結果を受け取る。

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
Get.to(() => const Pattern023View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern023Controller())));
```

## 関連パターン
- 前: Pattern 022
- 次: Pattern 024
