// Pattern 128: StreamController - テスト
// StreamController による手動 Stream 制御。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_128/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_128/service.dart';

void main() {
  group('Pattern 128: StreamController', () {
    test('model toJson and fromJson', () {
      const result = Pattern128Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern128Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern128Service();
      final result = await service.run();
      expect(result, isA<Pattern128Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
