# Pattern 138: SplitView

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
マスター/詳細画面分割 Navigator。

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
Get.to(() => const Pattern138View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern138Controller())));
```

## 関連パターン
- 前: Pattern 137
- 次: Pattern 139
