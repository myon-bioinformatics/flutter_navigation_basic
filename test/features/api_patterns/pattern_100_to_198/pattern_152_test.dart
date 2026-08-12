// Pattern 152: EtagCache - テスト
// ETag を使った条件付きリクエスト。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_152/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_152/service.dart';

void main() {
  group('Pattern 152: EtagCache', () {
    test('model toJson and fromJson', () {
      const result = Pattern152Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern152Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern152Service();
      final result = await service.run();
      expect(result, isA<Pattern152Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
