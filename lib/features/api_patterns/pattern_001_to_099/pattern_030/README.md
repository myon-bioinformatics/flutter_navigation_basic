# Pattern 030: BaseUrl

**カテゴリ**: 案B - API連携パターン

## 概要
ベース URL + エンドポイントの構造化実装。

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
Get.to(() => const Pattern030View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern030Controller())));
```

## 関連パターン
- 前: Pattern 029
- 次: Pattern 031
