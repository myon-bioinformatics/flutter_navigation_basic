// Pattern 147: AnimatedCrossFade - テスト
// AnimatedCrossFade によるクロスフェード。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_147/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_147/service.dart';

void main() {
  group('Pattern 147: AnimatedCrossFade', () {
    test('model toJson and fromJson', () {
      const result = Pattern147Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern147Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern147Service();
      final result = await service.run();
      expect(result, isA<Pattern147Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
