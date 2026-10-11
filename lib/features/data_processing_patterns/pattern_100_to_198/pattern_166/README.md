# Pattern 166: MVC

MVC パターンの Flutter 実装。

Flutter標準APIによる実動作の小さな例を
`lib/core/data_processing/counter_architecture_example.dart` にまとめた。
共通Widgetテストは`test/features/data_processing_patterns/counter_architecture_test.dart`。

この例はMVCの**最小構造**を示すものであり、完全なフレームワーク互換や
あらゆる役割の実装ではない。GetXの旧ダミーController、
message Model、100ms待つServiceと個別テストは撤去済み。
