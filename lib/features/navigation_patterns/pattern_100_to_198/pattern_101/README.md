# Pattern 101: BackStackInspect

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
現在のバックスタックを表示・管理。

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
Get.to(() => const Pattern101View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern101Controller())));
```

## 関連パターン
- 前: Pattern 100
- 次: Pattern 102
