# Flutter Navigation Basic — 792 パターン学習リファレンス

初心者から上級者まで対応した包括的なFlutterパターン集です。

## パターン分類

| カテゴリ | フォルダ | パターン数 | 説明 |
|---|---|---|---|
| 案A | navigation_patterns | 198 | ナビゲーション画面遷移パターン |
| 案B | api_patterns | 198 | API連携パターン |
| 案C | ui_theme_patterns | 198 | UI/テーマパターン |
| 案D | data_processing_patterns | 198 | データ処理パターン |

合計: **792パターン**

## 案A: ナビゲーション画面遷移パターン (198種)

| 範囲 | テーマ |
|---|---|
| 001-020 | 基本ナビゲーション (Push/Pop/Replace) |
| 021-040 | 名前付きルート (Named Routes) |
| 041-060 | ディープリンク対応 |
| 061-080 | Bottom / Tab / Drawer Navigation |
| 081-100 | Conditional Navigation (条件付き遷移) |
| 101-120 | バックスタック管理・BackPress Handling |
| 121-140 | Nested Navigation / 複数 Navigator |
| 141-160 | Animated Transitions (カスタムアニメーション) |
| 161-180 | Dialog / BottomSheet / Drawer モーダル |
| 181-198 | Advanced Patterns (複合ナビゲーション・状態保持) |

## 案B: API連携パターン (198種)

| 範囲 | テーマ |
|---|---|
| 001-030 | REST API基本 (GET/POST/PUT/DELETE/PATCH) |
| 031-060 | 認証・セキュリティ (JWT/OAuth/API Key) |
| 061-090 | WebSocket通信・Server-Sent Events (SSE) |
| 091-120 | JSON/JSONL/YAML処理と変換 |
| 121-150 | エラーハンドリング・リトライ・タイムアウト |
| 151-170 | キャッシング・CacheControl・ETag |
| 171-190 | ファイルアップロード/ダウンロード・マルチパート |
| 191-198 | 画像・動画・音声の埋め込みと取得 |

## 案C: UI/テーマパターン (198種)

| 範囲 | テーマ |
|---|---|
| 001-030 | Material Design基本 |
| 031-060 | Cupertino (iOS Style) |
| 061-090 | カスタムテーマ・動的テーマ切り替え |
| 091-120 | ライトモード/ダークモード・ダイナミックカラー |
| 121-150 | レスポンシブデザイン (モバイル/タブレット/Web/Desktop) |
| 151-175 | プラットフォーム固有 (iOS/Android/Web/macOS) |
| 176-190 | アクセシビリティ (セマンティクス・フォントサイズ調整) |
| 191-198 | アニメーション・トランジション・ジェスチャー応答 |

## 案D: データ処理パターン (198種)

| 範囲 | テーマ |
|---|---|
| 001-030 | フィルタリング・ソート・検索 |
| 031-060 | ページング・無限スクロール・仮想化 |
| 061-090 | キャッシング戦略・メモリ管理 |
| 091-120 | バリデーション・データ変換・正規化 |
| 121-150 | 非同期処理 (async/await・Future・Stream) |
| 151-170 | 状態管理 (GetX・Provider・Riverpod等) |
| 171-185 | 並び替え・追加・入れ替え機能 |
| 186-198 | バッチ処理・トランザクション・イベント駆動 |

## アーキテクチャ

```
lib/
├── core/              # コア基盤層
│   ├── config/        # アプリ設定
│   ├── exceptions/    # 例外定義
│   ├── logging/       # ロギング
│   ├── navigation/    # ナビゲーション管理
│   ├── services/      # 汎用サービス
│   └── utils/         # ユーティリティ
├── features/          # 792パターン実装
│   ├── navigation_patterns/    # 案A
│   ├── api_patterns/           # 案B
│   ├── ui_theme_patterns/      # 案C
│   └── data_processing_patterns/ # 案D
└── shared/            # 共通コンポーネント
    ├── themes/        # テーマ定義
    └── widgets/       # 再利用可能ウィジェット
```

## 各パターンの構成

```
pattern_NNN/
├── view.dart        # UI コンポーネント (GetView)
├── controller.dart  # ビジネスロジック (GetxController)
├── service.dart     # サービス層
├── model.dart       # データモデル
└── README.md        # パターン説明・使用例
```

## 設計原則

- **標準ライブラリ優先**: dart:convert, dart:async, dart:io を活用
- **依存関係最小化**: get, intl, logger, flutter_dotenv, shared_preferences のみ
- **マイクロコンポーネント化**: 各パターンは独立したモジュールとして設計
- **外出し**: 設定値・ルート・カラートークンはすべて外部ファイルに定義
- **JSON/JSONL/YAML対応**: 設定・データはテキスト形式で管理
- **OSI 7層対応**: L1〜L7 の各層に対応するパターンを含む
- **テスト可能な設計**: 全パターンにユニットテストを付属

## 実行方法

```bash
flutter pub get
flutter run
flutter test
```
