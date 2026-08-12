# Pattern 097: DarkModeConditional

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
ダークモード対応条件付き UI 遷移。

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
Get.to(() => const Pattern097View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern097Controller())));
```

## 関連パターン
- 前: Pattern 096
- 次: Pattern 098
