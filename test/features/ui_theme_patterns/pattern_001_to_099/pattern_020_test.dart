// Pattern 020: Stepper - テスト
// Stepper ウィジェットのカスタマイズ。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_020/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_020/service.dart';

void main() {
  group('Pattern 020: Stepper', () {
    test('model toJson and fromJson', () {
      const result = Pattern020Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern020Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern020Service();
      final result = await service.run();
      expect(result, isA<Pattern020Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
