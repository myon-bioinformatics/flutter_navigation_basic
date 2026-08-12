// Pattern 036: NamedRouteTabIndex - テスト
// Named Route でタブインデックスを指定。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_036/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_036/service.dart';

void main() {
  group('Pattern 036: NamedRouteTabIndex', () {
    test('model toJson and fromJson', () {
      const result = Pattern036Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern036Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern036Service();
      final result = await service.run();
      expect(result, isA<Pattern036Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
