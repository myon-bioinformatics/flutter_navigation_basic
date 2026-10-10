# Pattern 159: ValueNotifier

ValueNotifier の基本実装。

Flutter標準の `ValueNotifier` を使用した実際のカウンター状態通知を、`lib/core/data_processing/native_notifier_example.dart` で共通実装。
加算／リセット／disposeを `test/features/data_processing_patterns/native_notifier_test.dart` で検証する。
GetX Controller、ダミーService、message Modelは削除。Python/JSへFlutter通知機構を移していない。
