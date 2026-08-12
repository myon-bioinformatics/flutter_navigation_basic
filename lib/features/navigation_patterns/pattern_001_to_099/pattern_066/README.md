# Pattern 066: TabBarFixed

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
固定幅 TabBar の実装。

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
Get.to(() => const Pattern066View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern066Controller())));
```

## 関連パターン
- 前: Pattern 065
- 次: Pattern 067
