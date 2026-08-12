# Pattern 122: NestedNavTab

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
TabBar + ネスト Navigator の組み合わせ。

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
Get.to(() => const Pattern122View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern122Controller())));
```

## 関連パターン
- 前: Pattern 121
- 次: Pattern 123
