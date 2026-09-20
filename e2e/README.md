# Playwright E2E Tests

Web デバッグ対応 Playwright E2E テスト for flutter_navigation_basic。

## CI

- PR で `e2e/` を触ると **Non-Dart** workflow が Playwright の install + `--list` smoke だけ回す（Flutter は起動しない）。
- フル E2E（web build + Chromium）は GitHub Actions の **Non-Dart checks → Run workflow** で `run_playwright=true` のときだけ。Flutter/Pages の必須経路には載せない。visual snapshot spec は baseline 未登録の間は既存 Full E2E から分離し、`python tool/python/playwright.py snapshot --update` で明示的に生成する。

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

# テスト一覧（CI smoke と同用途）
python tool/python/playwright.py list

# Visual snapshot 検証（既定は Chromium）
python tool/python/playwright.py snapshot

# Visual snapshot の基準画像を更新
python tool/python/playwright.py snapshot --update

# HTML report
python tool/python/playwright.py report
```

Windows の cmd でも同じコマンドを利用できます。Python wrapper は `npx.cmd` を直接起動せず、`node node_modules/@playwright/test/cli.js` を呼ぶため、Windows の `.cmd` 実行差異を避けます。

Visual snapshot はブラウザ・OS・font差分の影響を受けやすいため、CLI の `snapshot` は既定で Chromium に固定しています。`--project` を指定すれば変更できます。baseline が未登録の環境ではまず `snapshot --update` を実行してください。passthrough 引数は `--project` / `--grep` / `--headed` など既知オプションの後ろに置いてください。

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
│   └── visual_snapshot.spec.ts # Visual regression baseline
├── fixtures/
│   └── test_data.json
└── utils/
    ├── helpers.ts
    └── constants.ts

tool/python/
└── playwright.py               # stdlib-only Playwright CLI wrapper
```
