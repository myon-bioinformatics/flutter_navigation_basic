# FLUTTER_NAVIGATION_BASIC_DEMO(macOS)
![Flutter Navigation Demo](https://raw.githubusercontent.com/myon-bioinformatics/flutter_navigation_basic/main/flutter_navigation_basic_demo.gif)

## Live Web Demo

After GitHub Pages is enabled for GitHub Actions and this branch is merged to `main`, the Flutter Web build is published at:

https://myon-bioinformatics.github.io/flutter_navigation_basic/

## Architecture

汎用的なFlutterアプリ基盤として、非機能要件（テーマ・ルート管理・共通ウィジェット・URLパラメータ標準化）を外出しした構成になっています。

```
lib/
├── main.dart                      # エントリポイント（MaterialApp設定のみ）
├── main_prod.dart                 # 本番エントリポイント（GetMaterialApp + 環境設定）
├── config/
│   ├── app_config.dart            # アプリ名・テーマカラー等の設定（旧来版）
│   └── routes.dart                # 198画面 + 意味ベースの名前付きルート
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
│   ├── home/
│   ├── screen2/
│   ├── screen3/
│   ├── screen4/
│   └── screen5/
├── screens/
│   ├── home_screen.dart
│   ├── hub_screen.dart            # 198画面を検索・一覧表示
│   ├── generic_screen.dart        # パターンデータとテンプレートを結合
│   ├── pattern_template_screen.dart # 11 UI templates × 18 variants = 198
│   ├── counter_playground_screen.dart
│   ├── irony_generator_screen.dart
│   └── composition_generator_screen.dart
├── shared/
│   ├── themes/
│   │   ├── app_theme.dart
│   │   └── color_constants.dart
│   └── widgets/
└── widgets/
    └── nav_button.dart
```

## 画面一覧

| Screen | 正式名 | 説明 |
|--------|--------|------|
| **Screen 1** | Home 🏠 | アプリのトップ画面。現在日付と主要デモへのナビゲーションを表示。 |
| **Screen 2** | Counter Playground 👾 | カウンターのインクリメントと条件分岐表示のサンプル。 |
| **Screen 3** | Irony Generator 🥐 | `Ironies.ironicList` からランダムなフレーズを表示するサンプル。 |
| **Screen 4** | Composition Generator 🎸 | `Composer.diatonicScaleList` からランダムなキーと BPM を生成するサンプル。 |
| **Screen 1–198** | Pattern Catalogue | `assets/screens.json` のパターン定義を11種類の代表UIテンプレートに18件ずつ割り当てて表示。 |

### 198画面の代表テンプレート

`PatternScreenTemplate` は List / Detail / Form / Search / Tabs / Bottom Navigation / Drawer / Dialog / Grid / Async State / Settings の11種類です。各テンプレートに18 Screen IDを割り当て、合計198画面を構成します。Navigation / API / Theme / Data のパターンデータは `assets/screens.json` を継続利用します。

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

- **テーマ管理**: `AppConfig` でカラースキームを一元管理。
- **ルート管理**: 数値URL `/screen1`〜`/screen198` は互換性のため維持し、手書きデモは意味ベースの定数名で参照。
- **共通ウィジェット**: 共通UIを再利用しつつ、代表テンプレートで画面構造の違いを確認可能。
- **データ分離**: 198件のパターン定義は `assets/screens.json` から読み込む。
- **Web対応**: Flutter Web / Chrome で同じルートと画面を確認可能。

## How to Run

```bash
flutter pub get
flutter run
```

Chrome でデバッグする場合:

```bash
flutter run -d chrome
```

Web release buildをローカル確認する場合:

```bash
flutter build web --release --base-href "/flutter_navigation_basic/"
```

`main` へのpush時は `.github/workflows/flutter-pages.yml` が analyze / test / web build を実行し、GitHub Pagesへデプロイします。
