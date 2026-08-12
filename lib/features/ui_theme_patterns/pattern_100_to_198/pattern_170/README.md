# Pattern 170: GestureScale

**カテゴリ**: 案C - UI/テーマパターン

## 概要
デスクトップ向けピンチズーム対応。

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
Get.to(() => const Pattern170View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern170Controller())));
```

## 関連パターン
- 前: Pattern 169
- 次: Pattern 171
