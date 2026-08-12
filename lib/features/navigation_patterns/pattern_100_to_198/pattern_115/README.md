# Pattern 115: RouteInfo

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
現在のルート情報を取得・表示。

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
Get.to(() => const Pattern115View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern115Controller())));
```

## 関連パターン
- 前: Pattern 114
- 次: Pattern 116
