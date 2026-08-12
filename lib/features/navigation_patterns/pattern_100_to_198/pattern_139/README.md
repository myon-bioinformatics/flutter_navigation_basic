# Pattern 139: NestedNavObserver

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
ネスト Navigator のイベント監視。

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
Get.to(() => const Pattern139View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern139Controller())));
```

## 関連パターン
- 前: Pattern 138
- 次: Pattern 140
