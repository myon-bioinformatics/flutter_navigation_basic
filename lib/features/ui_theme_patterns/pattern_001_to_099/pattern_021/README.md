# Pattern 021: DataTable

**カテゴリ**: 案C - UI/テーマパターン

## 概要
DataTable による表形式 UI。

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
Get.to(() => const Pattern021View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern021Controller())));
```

## 関連パターン
- 前: Pattern 020
- 次: Pattern 022
