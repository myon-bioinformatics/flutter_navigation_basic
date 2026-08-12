# Pattern 070: WebSocketStream

**カテゴリ**: 案B - API連携パターン

## 概要
Dart Stream として WebSocket を扱う。

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
Get.to(() => const Pattern070View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern070Controller())));
```

## 関連パターン
- 前: Pattern 069
- 次: Pattern 071
