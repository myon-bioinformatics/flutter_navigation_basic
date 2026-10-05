// Shared asset/UI contract for the multiple and nested filtering examples.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_002/service.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_002/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_003/service.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_003/view.dart';

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
  for (final multiple in [true, false]) {
    final name = multiple ? 'FilterMultiple' : 'FilterNested';
    final path = 'assets/data_processing/${multiple ? 'filter_multiple' : 'filter_nested'}.json';
    JsonListAsset service(AssetBundle? bundle) => multiple
        ? Pattern002Service(bundle: bundle)
        : Pattern003Service(bundle: bundle);
    Widget view(AssetBundle bundle) => multiple
        ? Pattern002View(bundle: bundle)
        : Pattern003View(bundle: bundle);

    test('$name loads its real Python-produced asset', () async {
      final values = await service(null).load();
      expect(values.map((value) => value['name']), multiple ? ['猫', '猫'] : ['A', 'C']);
    });

    test('$name consumes supplied values without evaluating predicates', () async {
      final values = await service(_Bundle((key) async {
        expect(key, path);
        return '{"values":["猫",null,"犬"]}';
      })).load();
      expect(values, ['猫', null, '犬']);
      expect(() => values.add('mutation'), throwsUnsupportedError);
    });

    for (final invalid in ['not json', '[]', '{}', '{"values":null}']) {
      test('$name rejects malformed asset: $invalid', () async {
        await expectLater(service(_Bundle((_) async => invalid)).load(), throwsFormatException);
      });
    }

    test('$name propagates a missing asset, without a mock fallback', () async {
      await expectLater(service(_Bundle((_) async => throw FlutterError('missing asset'))).load(),
          throwsA(isA<FlutterError>()));
    });

    testWidgets('$name shows loading, avoids duplicate loads, then shows values', (tester) async {
      final pending = Completer<String>();
      var calls = 0;
      await tester.pumpWidget(MaterialApp(home: view(_Bundle((_) {
        calls++;
        return pending.future;
      }))));
      final button = find.widgetWithText(ElevatedButton, '実行');
      await tester.tap(button);
      await tester.pump();
      expect(find.textContaining('実行中'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      await tester.tap(button);
      expect(calls, 1);
      pending.complete('{"values":["猫","猫"]}');
      await tester.pumpAndSettle();
      expect(find.textContaining('[猫, 猫]'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
    });

    testWidgets('$name exposes failure and retries without GetX registration', (tester) async {
      var attempts = 0;
      await tester.pumpWidget(MaterialApp(home: view(_Bundle((_) async =>
          attempts++ == 0 ? '{"values":null}' : '{"values":[]}'))));
      await tester.tap(find.text('実行'));
      await tester.pumpAndSettle();
      expect(find.textContaining('読み込み失敗'), findsOneWidget);
      expect(find.textContaining('Expected a JSON object'), findsOneWidget);
      await tester.tap(find.text('実行'));
      await tester.pumpAndSettle();
      expect(find.text('結果: []'), findsOneWidget);
      expect(find.textContaining('Expected a JSON object'), findsNothing);
      expect(attempts, 2);
    });

    testWidgets('$name ignores a completion after the view is disposed', (tester) async {
      final pending = Completer<String>();
      await tester.pumpWidget(MaterialApp(home: view(_Bundle((_) => pending.future))));
      await tester.tap(find.text('実行'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete('{"values":[1]}');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
