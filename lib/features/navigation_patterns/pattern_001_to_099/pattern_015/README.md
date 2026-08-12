# Pattern 015: TabBarView

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
TabController + TabBarView による横スクロールタブ。

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
Get.to(() => const Pattern015View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern015Controller())));
```

## 関連パターン
- 前: Pattern 014
- 次: Pattern 016
