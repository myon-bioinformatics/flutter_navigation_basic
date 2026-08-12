// Pattern 124: CircuitBreaker - テスト
// サーキットブレーカーパターン実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_124/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_124/service.dart';

void main() {
  group('Pattern 124: CircuitBreaker', () {
    test('model toJson and fromJson', () {
      const result = Pattern124Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern124Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern124Service();
      final result = await service.run();
      expect(result, isA<Pattern124Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
