# Pattern 044: AutoRefresh

**カテゴリ**: 案B - API連携パターン

## 概要
期限切れトークンの自動リフレッシュ。

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
Get.to(() => const Pattern044View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern044Controller())));
```

## 関連パターン
- 前: Pattern 043
- 次: Pattern 045
