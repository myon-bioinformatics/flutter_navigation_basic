// Pattern 035: NamedRouteModal - テスト
// Named Route としてのモーダル画面。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_035/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_035/service.dart';

void main() {
  group('Pattern 035: NamedRouteModal', () {
    test('model toJson and fromJson', () {
      const result = Pattern035Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern035Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern035Service();
      final result = await service.run();
      expect(result, isA<Pattern035Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
