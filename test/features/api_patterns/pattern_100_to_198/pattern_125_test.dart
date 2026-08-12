// Pattern 125: Fallback - テスト
// エラー時のフォールバック値返却。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_125/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_125/service.dart';

void main() {
  group('Pattern 125: Fallback', () {
    test('model toJson and fromJson', () {
      const result = Pattern125Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern125Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern125Service();
      final result = await service.run();
      expect(result, isA<Pattern125Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
