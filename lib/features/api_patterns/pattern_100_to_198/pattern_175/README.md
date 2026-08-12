# Pattern 175: ResumeUpload

**カテゴリ**: 案B - API連携パターン

## 概要
中断からの再開可能アップロード。

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
Get.to(() => const Pattern175View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern175Controller())));
```

## 関連パターン
- 前: Pattern 174
- 次: Pattern 176
