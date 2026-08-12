# Pattern 126: Timeout2

**カテゴリ**: 案B - API連携パターン

## 概要
より詳細なタイムアウト制御。

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
Get.to(() => const Pattern126View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern126Controller())));
```

## 関連パターン
- 前: Pattern 125
- 次: Pattern 127
