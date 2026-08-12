# Pattern 105: YamlConfig

**カテゴリ**: 案B - API連携パターン

## 概要
YAML ファイルから設定を読み込み。

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
Get.to(() => const Pattern105View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern105Controller())));
```

## 関連パターン
- 前: Pattern 104
- 次: Pattern 106
