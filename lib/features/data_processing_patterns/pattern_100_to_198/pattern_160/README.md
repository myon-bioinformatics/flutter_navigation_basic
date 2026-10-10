# Pattern 160: InheritedWidget

InheritedWidget による状態伝播。

Flutter標準の `InheritedWidget` を `lib/core/data_processing/inherited_catalogue_example.dart`
で実装。2つの値の状態伝播を `test/features/data_processing_patterns/inherited_catalogue_test.dart`
で検証します。GetXと旧成功メッセージだけのダミーServiceは撤去。
Python/JSにFlutterのWidget依存関係を移すことはしません。
