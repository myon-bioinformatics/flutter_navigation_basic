# Pattern 041: CupertinoPage

**カテゴリ**: 案C - UI/テーマパターン

## 概要
CupertinoPageRoute によるページ遷移。

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
Get.to(() => const Pattern041View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern041Controller())));
```

## 関連パターン
- 前: Pattern 040
- 次: Pattern 042
