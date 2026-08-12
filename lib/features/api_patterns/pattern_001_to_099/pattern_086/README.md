# Pattern 086: RealTimeList

**カテゴリ**: 案B - API連携パターン

## 概要
WebSocket でリアルタイム一覧更新。

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
Get.to(() => const Pattern086View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern086Controller())));
```

## 関連パターン
- 前: Pattern 085
- 次: Pattern 087
