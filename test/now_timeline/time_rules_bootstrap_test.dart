import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/now_timeline/presentation/time_rules_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'failed bootstrap reports asset context and rethrows the original error',
    () async {
      final errors = <FlutterErrorDetails>[];
      final originalHandler = FlutterError.onError;
      FlutterError.onError = errors.add;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        return ByteData.sublistView(Uint8List.fromList(utf8.encode('{broken')));
      });
      addTearDown(() {
        FlutterError.onError = originalHandler;
        messenger.setMockMessageHandler('flutter/assets', null);
        rootBundle.evict('assets/time/zone_table.json');
      });
      await expectLater(loadTimeRules(), throwsFormatException);
      expect(errors, hasLength(1));
      expect(errors.single.exception, isA<FormatException>());
      expect(errors.single.stack, isNotNull);
      expect(
        errors.single.context.toString(),
        contains('assets/time/zone_table.json'),
      );
    },
  );
}
