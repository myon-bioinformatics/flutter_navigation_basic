# Pattern 141: AnimatedPageRoute

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
カスタム PageRoute アニメーション。

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
Get.to(() => const Pattern141View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern141Controller())));
```

## 関連パターン
- 前: Pattern 140
- 次: Pattern 142
