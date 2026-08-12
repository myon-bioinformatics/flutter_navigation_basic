# Pattern 164: CacheAndNetwork

**カテゴリ**: 案B - API連携パターン

## 概要
Cache + Network 同時フェッチ戦略。

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
Get.to(() => const Pattern164View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern164Controller())));
```

## 関連パターン
- 前: Pattern 163
- 次: Pattern 165
