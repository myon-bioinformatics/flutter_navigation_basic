# Pattern 162: StateNotifier

StateNotifier パターン実装。

共有Flutter実装：`lib/core/data_processing/state_architecture_example.dart`。
`StateNotifier`の基本的な状態通知・イベント処理をパッケージなしで実装した例。
完全なStateNotifier/Riverpodライブラリや外部BLoCライブラリの互換実装ではない。
共通Widgetテスト：`test/features/data_processing_patterns/state_architecture_test.dart`。
旧GetX Controller、成功メッセージだけのModelとServiceは削除。
