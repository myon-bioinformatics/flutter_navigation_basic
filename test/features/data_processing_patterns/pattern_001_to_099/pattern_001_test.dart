// Pattern 001: FilterBasic - Flutter boundary test.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_001/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_001/service.dart';

void main() {
  group('Pattern 001: FilterBasic', () {
    test('model toJson and fromJson', () {
      const result = Pattern001Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern001Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service is a thin UI boundary without synthetic delay', () async {
      final stopwatch = Stopwatch()..start();
      final result = await Pattern001Service().run();
      stopwatch.stop();

      expect(result.message, contains('canonical stdlib Python filter'));
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
