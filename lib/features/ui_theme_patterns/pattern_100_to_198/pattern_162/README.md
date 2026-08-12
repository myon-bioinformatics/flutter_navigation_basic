# Pattern 162: IOSSplash

**カテゴリ**: 案C - UI/テーマパターン

## 概要
iOS スプラッシュスクリーン設定。

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
Get.to(() => const Pattern162View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern162Controller())));
```

## 関連パターン
- 前: Pattern 161
- 次: Pattern 163
