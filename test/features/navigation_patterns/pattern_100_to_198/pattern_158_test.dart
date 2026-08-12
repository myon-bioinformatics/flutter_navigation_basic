// Pattern 158: ZoomTransition - テスト
// ズームイン/アウト遷移アニメーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_158/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_158/service.dart';

void main() {
  group('Pattern 158: ZoomTransition', () {
    test('model toJson and fromJson', () {
      const result = Pattern158Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern158Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern158Service();
      final result = await service.run();
      expect(result, isA<Pattern158Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
