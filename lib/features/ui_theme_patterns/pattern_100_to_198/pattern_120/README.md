# Pattern 120: ThemeExport

**カテゴリ**: 案C - UI/テーマパターン

## 概要
テーマ設定の JSON エクスポート/インポート。

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
Get.to(() => const Pattern120View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern120Controller())));
```

## 関連パターン
- 前: Pattern 119
- 次: Pattern 121
