# Pattern 168: CacheStats

**カテゴリ**: 案B - API連携パターン

## 概要
キャッシュヒット率の統計収集。

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
Get.to(() => const Pattern168View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern168Controller())));
```

## 関連パターン
- 前: Pattern 167
- 次: Pattern 169
