# Playwright E2E Tests

Web デバッグ対応 Playwright E2E テスト for flutter_navigation_basic。

## CI

- PR で `e2e/` を触ると **Non-Dart** workflow が Playwright の install + `--list` smoke だけ回す（Flutter は起動しない）。
- フル E2E（web build + Chromium / Firefox / WebKit + mobile emulation の portable matrix）は GitHub Actions の **Non-Dart checks → Run workflow** で `run_playwright=true` のときだけ。Flutter/Pages の必須経路には載せない。visual snapshot spec は baseline 未登録の間は既存 Full E2E から分離し、`python tool/python/playwright.py snapshot --update` で明示的に生成する。

## セットアップ

```bash
cd e2e
npm install
```

## Flutter Web 起動

```bash
# プロジェクトルートで
flutter run -d web-server --web-port=8080
```

## Python CLI（推奨）

プロジェクトルートから Python のワンライナーで Playwright を呼び出せます。
Python 側の追加依存はなく、stdlib の `subprocess` から既存の `e2e/package.json` / Playwright を利用します。

```bash
# 全テスト
python tool/python/playwright.py test

# Chromium のみ
python tool/python/playwright.py test --project chromium

# portable 5-project allowlist（Photo Studio を含む）
python tool/python/playwright.py test \
  --project chromium --project firefox --project webkit \
  --project mobile-chromium --project mobile-webkit \
  --grep @portable \
  tests/hub_navigation.spec.ts tests/screen_navigation.spec.ts tests/photo_studio.spec.ts

# テスト一覧（CI smoke と同用途）
python tool/python/playwright.py list

# Visual snapshot 検証（既定は Chromium）
python tool/python/playwright.py snapshot

# Visual snapshot の基準画像を更新
python tool/python/playwright.py snapshot --update

# Photo Studio smoke/evidence (Flutter Web must already be on :8080)
python tool/python/playwright.py photo-evidence \
  --browser chromium \
  --fixture test/fixtures/photo_studio/import_compat/png_opaque_2x2.png \
  --output test-results/photo-studio-evidence.png \
  --timeout-ms 30000

# HTML report
python tool/python/playwright.py report
```

Windows の cmd でも同じコマンドを利用できます。Python wrapper は `npx.cmd` を直接起動せず、`node node_modules/@playwright/test/cli.js` を呼ぶため、Windows の `.cmd` 実行差異を避けます。

Playwright config は Chromium / Firefox / WebKit の3 projectを定義しており、CI/Dockerも3 engineをインストールします。Visual snapshot はブラウザ・OS・font差分の影響を受けやすいため、CLI の `snapshot` は既定で Chromium に固定しています。`--project` を指定すれば変更できます。baseline が未登録の環境ではまず `snapshot --update` を実行してください。passthrough 引数は `--project` / `--grep` / `--headed` など既知オプションの後ろに置いてください。

## Docker（Flutter/Node/Playwright を何もインストールしていない環境向け）

`Dockerfile.e2e` は「Flutter web release ビルド → 配信 → `tool/python/playwright.py` 実行」を1イメージに固めたものです。CI の `playwright` ジョブ（`.github/workflows/non-dart.yml`）と同じ手順・同じ Flutter/Node バージョンをコンテナ内で再現するので、ホスト側に Flutter SDK も Node もなくても、`docker` さえあれば実行・再現できます。

```bash
# プロジェクトルートで（初回はFlutter/Node/Chromium/Firefox/WebKitのダウンロードが入るため数分かかります）
docker build -f Dockerfile.e2e -t flutter-nav-e2e .

# デフォルト（hub + screen + Photo Studio の portable 5-project matrix）
docker run --rm \
  -v "$PWD/e2e/playwright-report:/repo/e2e/playwright-report" \
  -v "$PWD/e2e/test-results:/repo/e2e/test-results" \
  flutter-nav-e2e

# 高速なローカル確認: Chromium のみへ CMD を上書き
docker run --rm flutter-nav-e2e test --project chromium --grep @portable \
  tests/hub_navigation.spec.ts tests/screen_navigation.spec.ts tests/photo_studio.spec.ts

# Visual snapshot のスクショを撮りたいだけなら（コンテナ内の tool/python/playwright.py にそのまま引数が渡る）
docker run --rm \
  -v "$PWD/e2e/playwright-report:/repo/e2e/playwright-report" \
  -v "$PWD/e2e/test-results:/repo/e2e/test-results" \
  -v "$PWD/e2e/tests:/repo/e2e/tests" \
  flutter-nav-e2e snapshot --update
```

- `-v .../playwright-report`, `-v .../test-results` を bind mount すると、HTML レポート・失敗時スクショ・trace・video がホスト側にそのまま残ります（現状 CI の手動 `playwright` ジョブは artifact upload していないため、CI 経由よりこちらの方が確実に手元でスクショを回収できます）。
- `e2e/tests` も mount すると、`snapshot --update` で生成した `*-snapshots/*.png` baseline がホスト側のリポジトリにそのまま書き戻されます（コミットするかはレビューして判断してください）。
- Flutter/Node のバージョンは `Dockerfile.e2e` の `ARG FLUTTER_VERSION` / `ARG NODE_MAJOR` で固定しています。CI 側（`non-dart.yml` の `playwright` ジョブ）を更新するときはこちらも合わせてください。
- CI には現状組み込んでいません（このDockerfileはローカル/手元での再現用）。CIをDocker化するかどうかは別途判断が必要です。

## npm から直接実行

```bash
cd e2e

# ヘッドレス実行
npm test

# ブラウザ表示 (Web デバッグ)
npm run test:headed

# デバッグモード (ステップ実行)
npm run test:debug

# ハブ画面テストのみ
npm run test:hub

# 画面ナビゲーションテストのみ
npm run test:screens

# レポート表示
npm run report
```

## テスト構成

```
e2e/
├── playwright.config.ts        # Playwright 設定
├── package.json
├── tests/
│   ├── hub_navigation.spec.ts
│   ├── screen_navigation.spec.ts
│   ├── photo_studio.spec.ts       # Photo Studio representative portable flow
│   ├── photo_studio_ingress.spec.ts # ingress audit; clipboard case is Chromium-scoped
│   └── visual_snapshot.spec.ts # Visual regression baseline
├── fixtures/
│   └── test_data.json
└── utils/
    ├── helpers.ts
    └── constants.ts

tool/python/
└── playwright.py               # stdlib-only Playwright CLI wrapper

tool/docker/
└── e2e-entrypoint.sh           # Dockerfile.e2e's entrypoint (serve + run)

Dockerfile.e2e                  # Flutter build + Playwright, containerized
```
