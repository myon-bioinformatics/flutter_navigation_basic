# Pattern 080: M2Theme

**カテゴリ**: 案C - UI/テーマパターン

## 概要
Material Design 2 テーマ実装。

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
Get.to(() => const Pattern080View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern080Controller())));
```

## 関連パターン
- 前: Pattern 079
- 次: Pattern 081
