# Pattern 172: MultipartUpload

**カテゴリ**: 案B - API連携パターン

## 概要
Multipart Form Data 形式アップロード。

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
Get.to(() => const Pattern172View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern172Controller())));
```

## 関連パターン
- 前: Pattern 171
- 次: Pattern 173
