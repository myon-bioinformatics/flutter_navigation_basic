// Pattern 033: NamedRouteBinding - テスト
// Named Route と DI バインディングの連携。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_033/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_033/service.dart';

void main() {
  group('Pattern 033: NamedRouteBinding', () {
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
