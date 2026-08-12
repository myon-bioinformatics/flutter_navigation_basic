# Pattern 103: YamlRead

**カテゴリ**: 案B - API連携パターン

## 概要
YAML 文字列のパース (標準ライブラリ範囲)。

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
Get.to(() => const Pattern103View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern103Controller())));
```

## 関連パターン
- 前: Pattern 102
- 次: Pattern 104
