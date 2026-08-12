# Pattern 054: CupertinoRefresh

**カテゴリ**: 案C - UI/テーマパターン

## 概要
CupertinoSliverRefreshControl の実装。

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
Get.to(() => const Pattern054View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern054Controller())));
```

## 関連パターン
- 前: Pattern 053
- 次: Pattern 055
