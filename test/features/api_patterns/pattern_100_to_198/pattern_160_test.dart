// Pattern 160: CacheFirst - テスト
// Cache First フェッチ戦略。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_160/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_160/service.dart';

void main() {
  group('Pattern 160: CacheFirst', () {
    test('model toJson and fromJson', () {
      const result = Pattern160Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern160Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern160Service();
      final result = await service.run();
      expect(result, isA<Pattern160Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
