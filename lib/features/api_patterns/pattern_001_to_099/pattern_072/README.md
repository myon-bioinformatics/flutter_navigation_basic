# Pattern 072: SseReconnect

**カテゴリ**: 案B - API連携パターン

## 概要
SSE 切断時の自動再接続。

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
Get.to(() => const Pattern072View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern072Controller())));
```

## 関連パターン
- 前: Pattern 071
- 次: Pattern 073
