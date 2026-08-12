// Pattern 014: Slider - テスト
// Slider のカスタムスタイル。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_014/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_014/service.dart';

void main() {
  group('Pattern 014: Slider', () {
    test('model toJson and fromJson', () {
      const result = Pattern014Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern014Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern014Service();
      final result = await service.run();
      expect(result, isA<Pattern014Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
