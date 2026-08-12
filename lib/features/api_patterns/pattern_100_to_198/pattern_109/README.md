# Pattern 109: CsvParse

**カテゴリ**: 案B - API連携パターン

## 概要
CSV 形式のパースと DataFrame 風処理。

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
Get.to(() => const Pattern109View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern109Controller())));
```

## 関連パターン
- 前: Pattern 108
- 次: Pattern 110
