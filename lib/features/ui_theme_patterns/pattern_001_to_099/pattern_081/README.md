# Pattern 081: FontFamily

**カテゴリ**: 案C - UI/テーマパターン

## 概要
フォントファミリーのカスタマイズ。

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
Get.to(() => const Pattern081View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern081Controller())));
```

## 関連パターン
- 前: Pattern 080
- 次: Pattern 082
