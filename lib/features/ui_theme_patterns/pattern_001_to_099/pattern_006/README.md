# Pattern 006: FloatingActionButton

**カテゴリ**: 案C - UI/テーマパターン

## 概要
FAB の配置とスタイル。

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
Get.to(() => const Pattern006View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern006Controller())));
```

## 関連パターン
- 前: Pattern 005
- 次: Pattern 007
