// Pattern 033: BearerToken - テスト
// ****** Authorization ヘッダーに付与。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_033/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_033/service.dart';

void main() {
  group('Pattern 033: BearerToken', () {
    test('model toJson and fromJson', () {
      const result = Pattern033Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern033Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern033Service();
      final result = await service.run();
      expect(result, isA<Pattern033Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
