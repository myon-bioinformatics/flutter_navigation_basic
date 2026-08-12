// Pattern 198: AnimatedFeedback - テスト
// タップフィードバックアニメーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_198/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_198/service.dart';

void main() {
  group('Pattern 198: AnimatedFeedback', () {
    test('model toJson and fromJson', () {
      const result = Pattern198Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern198Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern198Service();
      final result = await service.run();
      expect(result, isA<Pattern198Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
