# Pattern 171: FileUploadBasic

**カテゴリ**: 案B - API連携パターン

## 概要
基本的なファイルアップロード実装。

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
Get.to(() => const Pattern171View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern171Controller())));
```

## 関連パターン
- 前: Pattern 170
- 次: Pattern 172
