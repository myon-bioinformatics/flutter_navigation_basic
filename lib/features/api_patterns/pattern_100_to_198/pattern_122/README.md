# Pattern 122: RetryLogic

**カテゴリ**: 案B - API連携パターン

## 概要
失敗時の固定間隔リトライ実装。

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
Get.to(() => const Pattern122View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern122Controller())));
```

## 関連パターン
- 前: Pattern 121
- 次: Pattern 123
