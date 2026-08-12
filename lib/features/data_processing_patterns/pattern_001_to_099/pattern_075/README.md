# Pattern 075: CacheSerialization

**カテゴリ**: 案D - データ処理パターン

## 概要
キャッシュのシリアライズ/デシリアライズ。

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
Get.to(() => const Pattern075View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern075Controller())));
```

## 関連パターン
- 前: Pattern 074
- 次: Pattern 076
