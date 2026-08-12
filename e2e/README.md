# Playwright E2E Tests

Web デバッグ対応 Playwright E2E テスト for flutter_navigation_basic。

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

## テスト実行

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
│   ├── hub_navigation.spec.ts  # ハブ画面テスト
│   └── screen_navigation.spec.ts  # 画面ナビゲーションテスト
├── fixtures/
│   └── test_data.json          # テストデータ
└── utils/
    ├── helpers.ts              # ヘルパー関数
    └── constants.ts            # 定数
```
