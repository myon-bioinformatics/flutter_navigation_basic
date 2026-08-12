# Pattern 186: BatchDownload

**カテゴリ**: 案B - API連携パターン

## 概要
複数ファイルの一括ダウンロード。

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
Get.to(() => const Pattern186View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern186Controller())));
```

## 関連パターン
- 前: Pattern 185
- 次: Pattern 187
