# Pattern 196: LazyLoadImage

**カテゴリ**: 案B - API連携パターン

## 概要
遅延ロード画像表示。

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
Get.to(() => const Pattern196View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern196Controller())));
```

## 関連パターン
- 前: Pattern 195
- 次: Pattern 197
