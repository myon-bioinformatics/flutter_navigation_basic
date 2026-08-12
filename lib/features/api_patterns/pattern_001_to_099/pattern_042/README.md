# Pattern 042: RequestSigning

**カテゴリ**: 案B - API連携パターン

## 概要
リクエスト署名 (タイムスタンプ+署名)。

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
Get.to(() => const Pattern042View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern042Controller())));
```

## 関連パターン
- 前: Pattern 041
- 次: Pattern 043
