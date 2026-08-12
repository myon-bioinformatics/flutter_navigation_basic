# 案A: ナビゲーション画面遷移パターン — 実装ガイド

## ディレクトリ構造

```
features/navigation_patterns/
├── pattern_001_to_099/
│   ├── pattern_001/ {view,controller,service,model,README}.dart
│   └── ...
├── pattern_100_to_198/
│   └── ...
└── docs/
```

## 実装の基本原則

1. **単一責任** — 各ファイルは1つの責務のみ
2. **依存性の方向** — view → controller → service → model
3. **標準ライブラリ優先** — dart:convert / dart:async / dart:io
4. **テスト可能な設計** — 依存性注入を活用
5. **JSON/YAML外出し** — assets/config/ に設定を外出し

## テスト実行
```bash
flutter test
flutter test test/features/{cat_key}/
```
