# Pattern 190: AccessibilityInspect

**カテゴリ**: 案C - UI/テーマパターン

## 概要
アクセシビリティ検査ツール表示 (擬似)。

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
Get.to(() => const Pattern190View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern190Controller())));
```

## 関連パターン
- 前: Pattern 189
- 次: Pattern 191
