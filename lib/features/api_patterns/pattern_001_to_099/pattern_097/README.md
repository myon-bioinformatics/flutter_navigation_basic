# Pattern 097: JsonDiff

**カテゴリ**: 案B - API連携パターン

## 概要
2つの JSON オブジェクトの差分比較。

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
Get.to(() => const Pattern097View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern097Controller())));
```

## 関連パターン
- 前: Pattern 096
- 次: Pattern 098
