# Pattern 038: Prefetch

**カテゴリ**: 案D - データ処理パターン

## 概要
スクロール位置検出による先読み。

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
Get.to(() => const Pattern038View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern038Controller())));
```

## 関連パターン
- 前: Pattern 037
- 次: Pattern 039
