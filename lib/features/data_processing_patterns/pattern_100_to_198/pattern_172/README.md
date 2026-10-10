# Pattern 172: ReorderList

## 概要
ReorderableListView による並び替え。

## 責務分離
- `view.dart`: 番号付きViewの互換入口。Flutterの実操作は共通の `lib/core/data_processing/interactive_pattern_example.dart` が担当する。
- 旧 `controller.dart` / `service.dart` / `model.dart` は100ms待機・固定成功文言だけのダミー実装だったため削除。
- データ処理・外部CLIの責務はFlutter UIとは独立させる。現状、この画面からPython CLIを実行する接続はない。
- `/screen172` から実際の操作画面を開ける。E2E専用の旧エイリアスも互換維持する。

## 検証
Flutter WidgetテストとPlaywrightの実操作検証を使用する。CIの同一headでの成功確認が必要。
