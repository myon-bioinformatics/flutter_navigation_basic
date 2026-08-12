# Pattern 077: NavigationRail

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
NavigationRail によるサイドナビゲーション。

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
Get.to(() => const Pattern077View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern077Controller())));
```

## 関連パターン
- 前: Pattern 076
- 次: Pattern 078
