# Pattern 134: WebLayout

**カテゴリ**: 案C - UI/テーマパターン

## 概要
Web 向けセンタリング+最大幅レイアウト。

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
Get.to(() => const Pattern134View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern134Controller())));
```

## 関連パターン
- 前: Pattern 133
- 次: Pattern 135
