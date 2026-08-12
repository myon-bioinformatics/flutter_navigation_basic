# Pattern 167: KeyboardPadding

**カテゴリ**: 案C - UI/テーマパターン

## 概要
キーボード表示時のレイアウト調整。

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
Get.to(() => const Pattern167View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern167Controller())));
```

## 関連パターン
- 前: Pattern 166
- 次: Pattern 168
