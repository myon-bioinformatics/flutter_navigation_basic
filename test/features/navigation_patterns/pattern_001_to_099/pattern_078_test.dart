// Pattern 078: NavigationRailExtended - テスト
// 拡張表示対応 NavigationRail。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_078/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_078/service.dart';

void main() {
  group('Pattern 078: NavigationRailExtended', () {
    test('model toJson and fromJson', () {
      const result = Pattern078Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern078Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern078Service();
      final result = await service.run();
      expect(result, isA<Pattern078Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
