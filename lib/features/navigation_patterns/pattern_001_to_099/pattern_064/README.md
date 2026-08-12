# Pattern 064: BottomNavHide

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
スクロール時に BottomNavBar を隠す。

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
Get.to(() => const Pattern064View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern064Controller())));
```

## 関連パターン
- 前: Pattern 063
- 次: Pattern 065
