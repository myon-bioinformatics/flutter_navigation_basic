// Pattern 157: ParallaxTransition - テスト
// パララックス効果付き遷移。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_157/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_157/service.dart';

void main() {
  group('Pattern 157: ParallaxTransition', () {
    test('model toJson and fromJson', () {
      const result = Pattern157Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern157Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern157Service();
      final result = await service.run();
      expect(result, isA<Pattern157Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
