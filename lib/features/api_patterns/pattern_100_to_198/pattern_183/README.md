# Pattern 183: DirectUpload

**カテゴリ**: 案B - API連携パターン

## 概要
署名付き URL への直接アップロード。

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
Get.to(() => const Pattern183View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern183Controller())));
```

## 関連パターン
- 前: Pattern 182
- 次: Pattern 184
