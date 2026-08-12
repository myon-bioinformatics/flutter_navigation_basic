// Pattern 130: StreamTransform - テスト
// Stream の map/where/expand 変換。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_130/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_130/service.dart';

void main() {
  group('Pattern 130: StreamTransform', () {
    test('model toJson and fromJson', () {
      const result = Pattern130Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern130Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern130Service();
      final result = await service.run();
      expect(result, isA<Pattern130Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
