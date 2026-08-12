# Pattern 132: TabletLayout

**カテゴリ**: 案C - UI/テーマパターン

## 概要
タブレット向けマスター/詳細レイアウト。

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
Get.to(() => const Pattern132View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern132Controller())));
```

## 関連パターン
- 前: Pattern 131
- 次: Pattern 133
