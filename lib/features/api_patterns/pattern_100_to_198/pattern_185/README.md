# Pattern 185: S3Presigned

**カテゴリ**: 案B - API連携パターン

## 概要
S3 署名付き URL アップロード (擬似)。

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
Get.to(() => const Pattern185View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern185Controller())));
```

## 関連パターン
- 前: Pattern 184
- 次: Pattern 186
