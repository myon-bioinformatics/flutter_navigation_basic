# Pattern 071: SseBasic

**カテゴリ**: 案B - API連携パターン

## 概要
基本的な SSE (Server-Sent Events) 受信。

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
Get.to(() => const Pattern071View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern071Controller())));
```

## 関連パターン
- 前: Pattern 070
- 次: Pattern 072
