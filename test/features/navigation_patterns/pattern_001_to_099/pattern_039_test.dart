// Pattern 039: NamedRoutePreload - テスト
// 遷移前にデータをプリロード。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_039/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_039/service.dart';

void main() {
  group('Pattern 039: NamedRoutePreload', () {
    test('model toJson and fromJson', () {
      const result = Pattern039Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern039Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern039Service();
      final result = await service.run();
      expect(result, isA<Pattern039Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
