# Pattern 078: NavigationRailExtended

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
拡張表示対応 NavigationRail。

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
Get.to(() => const Pattern078View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern078Controller())));
```

## 関連パターン
- 前: Pattern 077
- 次: Pattern 079
