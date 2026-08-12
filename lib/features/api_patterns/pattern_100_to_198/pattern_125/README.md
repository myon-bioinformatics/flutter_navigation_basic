# Pattern 125: Fallback

**カテゴリ**: 案B - API連携パターン

## 概要
エラー時のフォールバック値返却。

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
Get.to(() => const Pattern125View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern125Controller())));
```

## 関連パターン
- 前: Pattern 124
- 次: Pattern 126
