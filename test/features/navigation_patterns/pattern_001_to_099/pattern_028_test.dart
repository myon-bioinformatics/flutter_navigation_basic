// Pattern 028: NamedRouteTabBar - テスト
// Named Route と TabBar の連携。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_028/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_028/service.dart';

void main() {
  group('Pattern 028: NamedRouteTabBar', () {
    test('model toJson and fromJson', () {
      const result = Pattern028Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern028Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern028Service();
      final result = await service.run();
      expect(result, isA<Pattern028Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
