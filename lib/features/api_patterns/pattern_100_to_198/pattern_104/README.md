# Pattern 104: YamlWrite

**カテゴリ**: 案B - API連携パターン

## 概要
Dart オブジェクトから YAML 文字列を生成。

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
Get.to(() => const Pattern104View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern104Controller())));
```

## 関連パターン
- 前: Pattern 103
- 次: Pattern 105
