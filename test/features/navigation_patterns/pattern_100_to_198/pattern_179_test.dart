// Pattern 179: BannerWidget - テスト
// MaterialBanner によるバナー表示。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_179/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_179/service.dart';

void main() {
  group('Pattern 179: BannerWidget', () {
    test('model toJson and fromJson', () {
      const result = Pattern179Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern179Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern179Service();
      final result = await service.run();
      expect(result, isA<Pattern179Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
