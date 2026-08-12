# Pattern 089: DeltaCache

**カテゴリ**: 案D - データ処理パターン

## 概要
差分 (Delta) キャッシュ更新。

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
Get.to(() => const Pattern089View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern089Controller())));
```

## 関連パターン
- 前: Pattern 088
- 次: Pattern 090
