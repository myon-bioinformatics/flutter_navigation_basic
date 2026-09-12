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
│   └── routes.dart                # 198画面 + 意味ベースのexample routes
├── core/
│   ├── config/
│   │   └── app_config.dart        # 環境変数読み込み・環境切替（dev/prod）
│   ├── exceptions/
│   ├── logging/
│   ├── navigation/
│   │   ├── app_navigation.dart    # 意味ベースの画面遷移メソッド
│   │   └── route_names.dart       # example route名定数
│   ├── services/
│   └── utils/
│       └── url_params.dart        # URLパラメータ取得ユーティリティ
├── data/
│   ├── ironies.dart
│   └── composer.dart
├── features/
│   ├── home/
│   ├── counter_playground/        # 旧 screen2 · PAD-lite ダメージ/回復 + hold-to-repeat
│   ├── irony_generator/           # 旧 screen3
│   ├── composition_generator/     # 旧 screen4 · メトロノーム等
│   ├── coordinate_tool/           # 緯度経度 · Maps URL → DMS · 手動 Box
│   ├── photo_studio/              # 写真館 · 枠付きキャンバス
│   ├── now_timeline/
│   └── screen5/                   # URL Parameters
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
│   └── widgets/
│       └── hold_repeating_button.dart  # Material +/- の押し続け連打
└── widgets/
    └── nav_button.dart
```

## 画面一覧

| 種別 | 正式名 | URL | 説明 |
|------|--------|-----|------|
| Home | Home 🏠 | `/` | アプリのトップ画面。現在日付と主要デモへのナビゲーションを表示。 |
| Tool | Latitude / Longitude 📍 | `/tools/location/coordinates` | 緯度経度の検証・十進度／DMS・地図リンクに加え、手動の地理Box作成・コピー。Google / Apple Maps の共有 URL から座標抽出も可。 |
| Tool | 写真館 / Photo Studio | `/tools/media/photo-studio` | 写真の上に枠や印を載せるコーナー（旧 `/tools/location/bounding-box` は互換のため残置）。 |
| Tool | Now Timeline | `/tools/time/now-timeline` | 複数 IANA タイムゾーンを1本のクライアント側タイムラインにまとめる。 |
| Example | Counter Playground 👾 | `/examples/counter-playground` | カウンターの増減・履歴・undo。正の値ぶんダメージ／負の絶対値ぶん回復の軽いオーブ演出と、押し続けで連打できる +/-。 |
| Example | Irony Generator 🥐 | `/examples/irony-generator` | `Ironies.ironicList` からランダムなフレーズを表示。 |
| Example | Composition Generator 🎸 | `/examples/composition-generator` | キー／BPM 生成とビジュアルメトロノーム等の軽量プレ DAW。 |
| Catalogue | Screen 1–198 | `/screen1`〜`/screen198` | `assets/screens.json` の198件を11種類の代表UIテンプレートに18件ずつ割り当てて表示。 |

### Counter Playground（PAD-lite）

- **ダメージ / 回復**: カウンターが正ならその値だけダメージ、負なら絶対値ぶん回復としてラベル表示。
- **オーブ**: 炎・水・木・光・闇（攻撃）／ハート系（回復）の絵文字を軽い float アニメで表示（アセットなし）。
- **+/-**: `HoldRepeatingButton`（Material ボタン + `Listener` + `Timer`）。短押しは1回、押し続けで連打。VoiceOver / キーボードは Material の `onPressed` 経由。

元の `screen2/3/4` というファイル名・クラス名・featureディレクトリ名は意味ベースに変更しています。これらの手書きデモは `/examples/...` に分離し、`/screen1`〜`/screen198` はすべてパターンカタログ用として確保します。

### 198画面の代表テンプレート

`PatternScreenTemplate` は List / Detail / Form / Search / Tabs / Bottom Navigation / Drawer / Dialog / Grid / Async State / Settings の11種類です。各テンプレートに18 Screen IDを割り当て、**11 × 18 = 198** 画面を構成します。Navigation / API / Theme / Data のパターンデータは `assets/screens.json` を継続利用します。

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
- **ルート管理**: `/screen1`〜`/screen198` はパターンカタログ専用。手書きデモは `/examples/...` に分離。
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

既存のPlaywright E2Eも利用できます。Flutter Webを `http://localhost:8080` で配信した状態で:

```bash
cd e2e
npm install
npx playwright install chromium
npx playwright test --project=chromium
```

Pull Requestでは `.github/workflows/dart.yml` が analyze / test / Flutter Web build を検証します。Pinned は **core** と **patterns**（約792ファイル）に分割され、patterns は該当 path 変更時（および `main`）のみ走ります。Python / Playwright 系は `.github/workflows/non-dart.yml` が担当します。`main` への push 後は `.github/workflows/flutter-pages.yml` が同じ検証を通して GitHub Pages へデプロイします。

エージェント間の PR コメントは `AGENTS.md` の `from:` / `to:` ヘッダで宛先を明示します。
