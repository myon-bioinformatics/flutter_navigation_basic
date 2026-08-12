# Pattern 007: PathParams

**カテゴリ**: 案B - API連携パターン

## 概要
パスパラメータ付き REST エンドポイント。

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
Get.to(() => const Pattern007View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern007Controller())));
```

## 関連パターン
- 前: Pattern 006
- 次: Pattern 008
