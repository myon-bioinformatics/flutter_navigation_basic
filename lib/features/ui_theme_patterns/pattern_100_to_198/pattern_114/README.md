# Pattern 114: ColorHarmony

**カテゴリ**: 案C - UI/テーマパターン

## 概要
補色・類似色ハーモニーカラー生成。

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
Get.to(() => const Pattern114View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern114Controller())));
```

## 関連パターン
- 前: Pattern 113
- 次: Pattern 115
