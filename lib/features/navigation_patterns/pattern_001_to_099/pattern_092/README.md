# Pattern 092: ForceUpdate

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
強制アップデート画面への遷移制御。

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
Get.to(() => const Pattern092View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern092Controller())));
```

## 関連パターン
- 前: Pattern 091
- 次: Pattern 093
