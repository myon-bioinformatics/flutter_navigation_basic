# Pattern 040: PageSize

**カテゴリ**: 案D - データ処理パターン

## 概要
ページサイズ変更対応ページング。

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
Get.to(() => const Pattern040View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern040Controller())));
```

## 関連パターン
- 前: Pattern 039
- 次: Pattern 041
