# FLUTTER_NAVIGATION_BASIC_DEMO(macOS)
![Flutter Navigation Demo](https://raw.githubusercontent.com/myon-bioinformatics/flutter_navigation_basic/main/flutter_navigation_basic_demo.gif)

## Architecture

汎用的なFlutterアプリ基盤として、非機能要件（テーマ・ルート管理・共通ウィジェット・URLパラメータ標準化）を外出しした構成になっています。

```
lib/
├── main.dart                      # エントリポイント（MaterialApp設定のみ）
├── main_prod.dart                 # 本番エントリポイント（GetMaterialApp + 環境設定）
├── config/
│   ├── app_config.dart            # アプリ名・テーマカラー等の設定（旧来版）
│   └── routes.dart                # 名前付きルート定義（旧来版）
├── core/
│   ├── config/
│   │   └── app_config.dart        # 環境変数読み込み・環境切替（dev/prod）
│   ├── exceptions/
│   │   ├── app_exception.dart     # アプリ独自例外クラス
│   │   └── error_handler.dart     # 例外の捕捉・ラップ処理
│   ├── logging/
│   │   └── logger_service.dart    # ログ出力サービス（logger パッケージ使用）
│   ├── navigation/
│   │   ├── app_navigation.dart    # 画面遷移メソッド集・GetPage ルート定義
│   │   └── route_names.dart       # ルート名定数
│   ├── services/
│   │   ├── base_controller.dart   # 全 Controller の基底クラス（ローディング・エラー管理）
│   │   └── storage_service.dart   # SharedPreferences ラッパー
│   └── utils/
│       └── url_params.dart        # URLパラメータ取得ユーティリティ（非機能・標準化）
├── data/
│   ├── ironies.dart               # Ironies データクラス（皮肉フレーズリスト）
│   └── composer.dart              # Composer データクラス（ダイアトニックスケール）
├── features/
│   ├── home/                      # Screen1: HomeApp
│   ├── screen2/                   # Screen2: Trick and Mock
│   ├── screen3/                   # Screen3: Irony
│   ├── screen4/                   # Screen4: Composition
│   └── screen5/                   # Screen5: URL Parameters
├── screens/                       # 旧来の画面実装（参照用）
├── shared/
│   ├── themes/
│   │   ├── app_theme.dart         # テーマ定義（light/dark）
│   │   └── color_constants.dart   # カラー定数
│   └── widgets/
│       ├── custom_app_bar.dart    # 共通 AppBar
│       ├── custom_button.dart     # 共通ボタン
│       ├── error_widget.dart      # エラー表示ウィジェット
│       └── loading_widget.dart    # ローディング表示ウィジェット
└── widgets/
    └── nav_button.dart            # 共通ナビゲーションボタン（旧来版）
```

## 画面一覧

| Screen | タイトル | 説明 |
|--------|----------|------|
| **Screen 1** | HomeApp🏠 | アプリのトップ画面。現在日付を表示し、他の全画面へのナビゲーションボタンを提供する。 |
| **Screen 2** | Trick and Mock👾 | カウンターのインクリメントと条件分岐表示（10以上で "Too much😈" を表示）。モックボタンの配置サンプル。 |
| **Screen 3** | Irony🥐 | ランダムに選ばれた皮肉フレーズを表示するサンプル。`Ironies.ironicList` からランダム取得するパターンを示す。 |
| **Screen 4** | Composition🎸 | ランダムなキー（調性）と BPM を表示する音楽コンポジションサンプル。`Composer.diatonicScaleList` を使用。 |
| **Screen 5** | URL Params🔗 | URLパラメータのよくある取得ケース（Case 1〜18）を一覧表示する非機能デモ画面。`UrlParams` ユーティリティの使い方を確認できる。 |

## URLパラメータ標準化（非機能）

`lib/core/utils/url_params.dart` に GetX のパスパラメータ・クエリパラメータを型安全に取得するユーティリティを集約しています。

| Case | メソッド | 説明 | 例 |
|------|---------|------|----|
| 1 | `UrlParams.pathString('key')` | パスパラメータ → String | `/user/:id` → `'42'` |
| 2 | `UrlParams.pathInt('key')` | パスパラメータ → int | `/item/:id` → `10` |
| 3 | `UrlParams.pathDouble('key')` | パスパラメータ → double | `/price/:amount` → `3.14` |
| 4 | `UrlParams.pathBool('key')` | パスパラメータ → bool | `/feature/:enabled` → `true` |
| 5 | `UrlParams.hasPath('key')` | パスパラメータの存在確認 | `/resource/:key` |
| 6 | `UrlParams.queryString('key')` | クエリパラメータ → String | `?q=flutter` |
| 7 | `UrlParams.queryInt('key')` | クエリパラメータ → int | `?page=2` |
| 8 | `UrlParams.queryDouble('key')` | クエリパラメータ → double | `?zoom=1.5` |
| 9 | `UrlParams.queryBool('key')` | クエリパラメータ → bool | `?darkMode=true` |
| 10 | `UrlParams.hasQuery('key')` | クエリパラメータの存在確認 | `?debug=1` |
| 11 | `UrlParams.queryList('key')` | カンマ区切りクエリ → List\<String\> | `?tags=flutter,dart` |
| 12 | `UrlParams.queryIntList('key')` | カンマ区切りクエリ → List\<int\> | `?ids=1,2,3` |
| 13 | `UrlParams.allPathParams()` | 全パスパラメータ → Map | `/user/:userId/post/:postId` |
| 14 | `UrlParams.allQueryParams()` | 全クエリパラメータ → Map | `?q=hello&lang=ja` |
| 15 | `UrlParams.pathDate('key')` | パスパラメータ → DateTime? | `/schedule/2024-01-15` |
| 16 | `UrlParams.queryDate('key')` | クエリパラメータ → DateTime? | `?from=2024-01-01` |
| 17 | `UrlParams.pathEnum('key', values, fallback: ...)` | パスパラメータ → Enum | `/mode/dark` |
| 18 | `UrlParams.queryEnum('key', values, fallback: ...)` | クエリパラメータ → Enum | `?order=asc` |

> 最大 198 ケースまで拡張可能。新しい取得パターンは `UrlParams` クラスにメソッドを追加し、`UrlParamsCases.cases` にエントリを追記するだけ。

### 設計方針

- **テーマ管理**: `AppConfig` でカラースキームを一元管理。色の変更は `app_config.dart` の `seedColor` だけ変えればよい。
- **ルート管理**: `AppNavigation` / `RouteNames` で名前付きルートを定義。`Get.toNamed` を使用し、Home への戻りは `Get.offAllNamed` でスタッククリア。
- **共通ウィジェット**: `CustomButton` / `CustomAppBar` で画面遷移ボタン・ヘッダーのパターンを共通化。
- **データ分離**: 各画面固有のデータ（皮肉リスト・音楽キーリスト）は `data/` 配下に独立させ、差し替えが容易。
- **URLパラメータ標準化**: `UrlParams` ユーティリティで型安全な取得パターンを非機能として集約。Controller 内で直接 `Get.parameters` / `Get.query` を書かずに済む。

## How to Run

```bash
flutter run
```

Web で起動する場合:

```bash
flutter run -d chrome
```
