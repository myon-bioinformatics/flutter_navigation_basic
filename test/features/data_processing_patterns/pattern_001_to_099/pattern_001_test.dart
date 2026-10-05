// Pattern 001: Python-produced asset -> Flutter loading/result/error boundary.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_001/controller.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_001/model.dart';
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

  test('FilterBasic model compatibility roundtrip', () {
    final result = Pattern001Result.fromJson(
      Pattern001Result(message: 'example').toJson(),
    );
    expect(result.message, 'example');
  });

  test('FilterBasic reads the real bundled Python result', () async {
    final result = await Pattern001Service().run();
    expect(result.message, contains('[1, 1]'));
  });

  test('FilterBasic consumes supplied results without filtering again', () async {
    final bundle = _Bundle((path) async {
      expect(path, 'assets/data_processing/filter_basic.json');
      return '{"values":["猫",null,"犬"]}';
    });
    expect((await Pattern001Service(bundle: bundle).run()).message,
        contains('[猫, null, 犬]'));
  });

  for (final invalid in ['not json', '[]', '{}', '{"values":"invalid"}']) {
    test('FilterBasic rejects malformed result: $invalid', () async {
      final service = Pattern001Service(bundle: _Bundle((_) async => invalid));
      await expectLater(service.run(), throwsFormatException);
    });
  }

  test('FilterBasic propagates missing asset instead of returning a mock', () async {
    final service = Pattern001Service(
      bundle: _Bundle((_) async => throw FlutterError('missing asset')),
    );
    await expectLater(service.run(), throwsA(isA<FlutterError>()));
  });

  testWidgets('FilterBasic UI shows loading then actual processed values', (tester) async {
    Get.testMode = true;
    addTearDown(() async {
      await Get.reset();
      Get.testMode = false;
    });
    final pending = Completer<String>();
    final controller = Get.put(Pattern001Controller(
      service: Pattern001Service(bundle: _Bundle((_) => pending.future)),
    ));
    await tester.pumpWidget(const MaterialApp(home: Pattern001View()));
    await tester.tap(find.text('実行'));
    await tester.pump();
    expect(find.textContaining('実行中'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
    pending.complete('{"values":["猫","猫"]}');
    await tester.pumpAndSettle();
    expect(find.textContaining('[猫, 猫]'), findsOneWidget);
    expect(controller.isLoading.value, isFalse);
  });

  testWidgets('FilterBasic UI exposes errors and permits retry', (tester) async {
    Get.testMode = true;
    addTearDown(() async {
      await Get.reset();
      Get.testMode = false;
    });
    var attempts = 0;
    final controller = Get.put(Pattern001Controller(
      service: Pattern001Service(bundle: _Bundle((_) async =>
          attempts++ == 0 ? '{"values":null}' : '{"values":[7]}')),
    ));
    await tester.pumpWidget(const MaterialApp(home: Pattern001View()));
    await tester.tap(find.text('実行'));
    await tester.pumpAndSettle();
    expect(controller.hasError.value, isTrue);
    expect(find.textContaining('読み込み失敗'), findsOneWidget);
    expect(find.textContaining('Expected a JSON object'), findsOneWidget);
    await tester.tap(find.text('実行'));
    await tester.pumpAndSettle();
    expect(controller.hasError.value, isFalse);
    expect(find.textContaining('[7]'), findsOneWidget);
    expect(find.textContaining('Expected a JSON object'), findsNothing);
  });
}
