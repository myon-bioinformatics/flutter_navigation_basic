# Pattern 169: NoCacheHeader

**カテゴリ**: 案B - API連携パターン

## 概要
no-cache ヘッダーによるキャッシュ無効化。

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
Get.to(() => const Pattern169View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern169Controller())));
```

## 関連パターン
- 前: Pattern 168
- 次: Pattern 170
