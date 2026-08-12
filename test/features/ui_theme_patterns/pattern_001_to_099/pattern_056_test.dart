// Pattern 056: AdaptiveWidget - テスト
// プラットフォームに応じた Adaptive ウィジェット。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_056/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_056/service.dart';

void main() {
  group('Pattern 056: AdaptiveWidget', () {
    test('model toJson and fromJson', () {
      const result = Pattern056Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern056Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern056Service();
      final result = await service.run();
      expect(result, isA<Pattern056Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
