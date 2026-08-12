# Pattern 180: DrawerModal

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
モーダル形式の Drawer ダイアログ。

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
Get.to(() => const Pattern180View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern180Controller())));
```

## 関連パターン
- 前: Pattern 179
- 次: Pattern 181
