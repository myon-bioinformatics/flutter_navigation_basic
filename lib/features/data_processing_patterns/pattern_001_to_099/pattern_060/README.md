# Pattern 060: HeatmapData

**カテゴリ**: 案D - データ処理パターン

## 概要
ヒートマップ向けデータ集計。

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
Get.to(() => const Pattern060View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern060Controller())));
```

## 関連パターン
- 前: Pattern 059
- 次: Pattern 061
