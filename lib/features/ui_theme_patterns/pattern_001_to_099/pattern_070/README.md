# Pattern 070: ThemePersist

**カテゴリ**: 案C - UI/テーマパターン

## 概要
テーマ設定を SharedPreferences で永続化。

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
Get.to(() => const Pattern070View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern070Controller())));
```

## 関連パターン
- 前: Pattern 069
- 次: Pattern 071
