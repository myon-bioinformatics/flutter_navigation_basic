# FLUTTER_NAVIGATION_BASIC_DEMO(macOS)
![Flutter Navigation Demo](https://raw.githubusercontent.com/myon-bioinformatics/flutter_navigation_basic/main/flutter_navigation_basic_demo.gif)

## Architecture

汎用的なFlutterアプリ基盤として、非機能要件（テーマ・ルート管理・共通ウィジェット）を外出しした構成になっています。

```
lib/
├── main.dart              # エントリポイント（MaterialApp設定のみ）
├── config/
│   ├── app_config.dart    # アプリ名・テーマカラー等の設定
│   └── routes.dart        # 名前付きルート定義
├── data/
│   ├── ironies.dart       # Ironies データクラス
│   └── composer.dart      # Composer データクラス
├── screens/
│   ├── home_screen.dart   # Screen1: HomeApp
│   ├── screen2.dart       # Screen2: Trick and Mock
│   ├── screen3.dart       # Screen3: Irony
│   └── screen4.dart       # Screen4: Composition
└── widgets/
    └── nav_button.dart    # 共通ナビゲーションボタン
```

### 設計方針

- **テーマ管理**: `AppConfig` でカラースキームを一元管理。色の変更は `app_config.dart` の `seedColor` だけ変えればよい。
- **ルート管理**: `AppRoutes` で名前付きルートを定義。`Navigator.pushNamed` を使用し、Home への戻りは `pushNamedAndRemoveUntil` でスタッククリア。
- **共通ウィジェット**: `NavButton` で画面遷移ボタンのパターンを共通化。新画面追加時も同じウィジェットを使うだけ。
- **データ分離**: 各画面固有のデータ（皮肉リスト・音楽キーリスト）は `data/` 配下に独立させ、差し替えが容易。

## How to Run

```bash
flutter run
```

Web で起動する場合:

```bash
flutter run -d chrome
```
