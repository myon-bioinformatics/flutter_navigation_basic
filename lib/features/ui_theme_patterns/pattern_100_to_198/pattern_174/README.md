# Pattern 174: CameraAware

**カテゴリ**: 案C - UI/テーマパターン

## 概要
カメラノッチ対応レイアウト。

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
Get.to(() => const Pattern174View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern174Controller())));
```

## 関連パターン
- 前: Pattern 173
- 次: Pattern 175
