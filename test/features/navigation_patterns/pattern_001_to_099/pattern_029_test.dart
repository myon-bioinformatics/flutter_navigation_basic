// Pattern 029: NamedRouteGroup - テスト
// ルートをグルーピングして管理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_029/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_029/service.dart';

void main() {
  group('Pattern 029: NamedRouteGroup', () {
    test('model toJson and fromJson', () {
      const result = Pattern029Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern029Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern029Service();
      final result = await service.run();
      expect(result, isA<Pattern029Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
