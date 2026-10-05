// FilterBasic uses the same generated-asset/UI boundary as 002/003.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_001/service.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_001/view.dart';

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

  test('FilterBasic loads its real Python-produced asset', () async {
    expect(await Pattern001Service().load(), [1, 1]);
  });

  test('FilterBasic consumes supplied values without evaluating predicates', () async {
    final values = await Pattern001Service(bundle: _Bundle((key) async {
      expect(key, 'assets/data_processing/filter_basic.json');
      return '{"values":["猫",null,"犬"]}';
    })).load();
    expect(values, ['猫', null, '犬']);
    expect(() => values.add('mutation'), throwsUnsupportedError);
  });

  for (final invalid in ['not json', '[]', '{}', '{"values":null}']) {
    test('FilterBasic rejects malformed asset: $invalid', () async {
      await expectLater(
        Pattern001Service(bundle: _Bundle((_) async => invalid)).load(),
        throwsFormatException,
      );
    });
  }

  test('FilterBasic propagates a missing asset, without a mock fallback', () async {
    await expectLater(
      Pattern001Service(bundle: _Bundle((_) async => throw FlutterError('missing asset'))).load(),
      throwsA(isA<FlutterError>()),
    );
  });

  testWidgets('FilterBasic shows loading once then actual processed values', (tester) async {
    final pending = Completer<String>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Pattern001View(bundle: _Bundle((_) {
        calls++;
        return pending.future;
      })),
    ));
    final button = find.widgetWithText(ElevatedButton, '実行');
    await tester.tap(button);
    await tester.pump();
    expect(find.textContaining('実行中'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    await tester.tap(button);
    expect(calls, 1);
    pending.complete('{"values":["猫","猫"]}');
    await tester.pumpAndSettle();
    expect(find.text('結果: [猫, 猫]'), findsOneWidget);
  });

  testWidgets('FilterBasic exposes failure and retries without GetX registration', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(
      home: Pattern001View(bundle: _Bundle((_) async =>
          attempts++ == 0 ? '{"values":null}' : '{"values":[7]}')),
    ));
    await tester.tap(find.text('実行'));
    await tester.pumpAndSettle();
    expect(find.textContaining('読み込み失敗'), findsOneWidget);
    expect(find.textContaining('Expected a JSON object'), findsOneWidget);
    await tester.tap(find.text('実行'));
    await tester.pumpAndSettle();
    expect(find.text('結果: [7]'), findsOneWidget);
    expect(find.textContaining('Expected a JSON object'), findsNothing);
    expect(attempts, 2);
  });
}
