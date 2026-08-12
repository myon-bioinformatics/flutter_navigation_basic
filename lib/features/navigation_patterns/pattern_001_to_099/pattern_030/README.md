# Pattern 030: NamedRouteDynamic

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
動的セグメントを含む Named Route。

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
Get.to(() => const Pattern030View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern030Controller())));
```

## 関連パターン
- 前: Pattern 029
- 次: Pattern 031
