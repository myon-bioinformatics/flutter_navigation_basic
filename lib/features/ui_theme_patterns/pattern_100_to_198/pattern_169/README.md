# Pattern 169: MouseRegion

**カテゴリ**: 案C - UI/テーマパターン

## 概要
マウスカーソル領域検出 (デスクトップ)。

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
Get.to(() => const Pattern169View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern169Controller())));
```

## 関連パターン
- 前: Pattern 168
- 次: Pattern 170
