# Pattern 029: TopN

**カテゴリ**: 案D - データ処理パターン

## 概要
上位 N 件の効率的な取得。

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
Get.to(() => const Pattern029View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern029Controller())));
```

## 関連パターン
- 前: Pattern 028
- 次: Pattern 030
