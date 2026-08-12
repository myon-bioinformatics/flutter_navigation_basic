# Pattern 116: SystemBrightness

**カテゴリ**: 案C - UI/テーマパターン

## 概要
システム輝度に連動するテーマ。

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
Get.to(() => const Pattern116View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern116Controller())));
```

## 関連パターン
- 前: Pattern 115
- 次: Pattern 117
