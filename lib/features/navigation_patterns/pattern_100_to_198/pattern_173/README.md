# Pattern 173: ColorPicker

**カテゴリ**: 案A - ナビゲーション画面遷移パターン

## 概要
カラー選択ダイアログ。

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
Get.to(() => const Pattern173View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern173Controller())));
```

## 関連パターン
- 前: Pattern 172
- 次: Pattern 174
