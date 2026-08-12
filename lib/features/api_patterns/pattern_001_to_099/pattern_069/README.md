# Pattern 069: WebSocketAuth

**カテゴリ**: 案B - API連携パターン

## 概要
WebSocket 接続時の認証トークン付与。

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
Get.to(() => const Pattern069View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern069Controller())));
```

## 関連パターン
- 前: Pattern 068
- 次: Pattern 070
