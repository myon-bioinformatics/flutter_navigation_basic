# Pattern 160: GlassTransition

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
ガラス効果アニメーション遷移。

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
Get.to(() => const Pattern160View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern160Controller())));
```

## 関連パターン
- 前: Pattern 159
- 次: Pattern 161
