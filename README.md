# FLUTTER_NAVIGATION_BASIC_DEMO(macOS)
![Flutter Navigation Demo](https://raw.githubusercontent.com/myon-bioinformatics/flutter_navigation_basic/main/flutter_navigation_basic_demo.gif)

## アーキテクチャ概要

シンプルなFlutterナビゲーション実装をモダンで拡張性の高い基盤にリファクタリングしたプロジェクトです。

### ディレクトリ構造

```
lib/
├── core/
│   ├── config/          # 環境設定管理（.env対応）
│   ├── exceptions/      # アプリ共通例外・エラーハンドリング
│   ├── logging/         # ロギングサービス
│   ├── navigation/      # ルート名定義・ナビゲーション管理
│   └── services/        # 汎用サービス層（Storage、BaseController）
├── features/
│   ├── home/            # ホーム画面
│   ├── screen2/         # カウンター画面
│   ├── screen3/         # アイロニー画面
│   └── screen4/         # 作曲ヒント画面
├── shared/
│   ├── widgets/         # 共通UIコンポーネント
│   └── themes/          # テーマ・カラー定数
├── main.dart            # 開発環境エントリーポイント
└── main_prod.dart       # 本番環境エントリーポイント
```

### 主要ライブラリ

| ライブラリ | 用途 |
|---|---|
| `get` | 状態管理・ナビゲーション |
| `logger` | ロギング |
| `flutter_dotenv` | 環境変数管理（.env） |
| `shared_preferences` | ローカルストレージ |

### 環境別実行

```bash
# 開発環境
flutter run -t lib/main.dart

# 本番環境
flutter run -t lib/main_prod.dart
```

### テスト

```bash
flutter test
```
