# Pattern 098: SystemAccent

**カテゴリ**: 案C - UI/テーマパターン

## 概要
システムアクセントカラーの適用。

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
Get.to(() => const Pattern098View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern098Controller())));
```

## 関連パターン
- 前: Pattern 097
- 次: Pattern 099
