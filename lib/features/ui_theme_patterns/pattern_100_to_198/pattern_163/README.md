# Pattern 163: WebFavicon

**カテゴリ**: 案C - UI/テーマパターン

## 概要
Web ファビコン設定。

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
Get.to(() => const Pattern163View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern163Controller())));
```

## 関連パターン
- 前: Pattern 162
- 次: Pattern 164
