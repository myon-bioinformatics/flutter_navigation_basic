# Pattern 094: DarkModeIcon

**カテゴリ**: 案C - UI/テーマパターン

## 概要
ダークモードに応じたアイコン切り替え。

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
Get.to(() => const Pattern094View(),
  binding: BindingsBuilder(() => Get.lazyPut(() => Pattern094Controller())));
```

## 関連パターン
- 前: Pattern 093
- 次: Pattern 095
