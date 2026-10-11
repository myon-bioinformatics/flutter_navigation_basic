// Pattern 113: DataDeduplicate report boundary.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_113/service.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_113/view.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.read);
  final Future<String> Function(String) read;

  @override
  Future<String> loadString(String key, {bool cache = true}) => read(key);

  @override
  Future<ByteData> load(String key) => throw StateError('Unexpected byte load');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the real Python-produced deduplication report', () async {
    final values = await Pattern113Service().load();
    expect(values, [
      {
        'input_count': 6,
        'unique_count': 3,
        'duplicate_count': 3,
        'has_duplicates': true,
      },
    ]);
  });

  test('consumes supplied report records without running deduplication in Dart', () async {
    final values = await Pattern113Service(bundle: _Bundle((key) async {
      expect(key, 'assets/data_processing/deduplicate_report.json');
      return '{"values":[{"input_count":2,"unique_count":2,"duplicate_count":0,"has_duplicates":false}]}';
    })).load();
    expect(values.single['has_duplicates'], isFalse);
    expect(() => values.add('mutation'), throwsUnsupportedError);
  });

  test('rejects a malformed report asset shape', () async {
    await expectLater(
      Pattern113Service(bundle: _Bundle((_) async => '{"values":null}')).load(),
      throwsFormatException,
    );
  });

  testWidgets('shows loading once and then the generated report', (tester) async {
    final pending = Completer<String>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Pattern113View(bundle: _Bundle((_) {
        calls++;
        return pending.future;
      })),
    ));
    expect(find.text('Pattern 113: DataDeduplicate'), findsOneWidget);
    final button = find.widgetWithText(ElevatedButton, '実行');
    await tester.tap(button);
    await tester.pump();
    expect(find.textContaining('実行中'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    await tester.tap(button);
    expect(calls, 1);
    pending.complete(
      '{"values":[{"input_count":6,"unique_count":3,"duplicate_count":3,"has_duplicates":true}]}',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('duplicate_count: 3'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
  });
}
