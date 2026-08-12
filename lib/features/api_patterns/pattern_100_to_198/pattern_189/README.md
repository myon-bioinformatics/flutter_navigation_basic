# Pattern 189: ContentType

**カテゴリ**: 案B - API連携パターン

## 概要
Content-Type 自動判定アップロード。

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
Get.to(() => const Pattern189View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern189Controller())));
```

## 関連パターン
- 前: Pattern 188
- 次: Pattern 190
