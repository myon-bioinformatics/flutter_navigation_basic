// Pattern 096: DarkModeColor - テスト
// ダークモードに適したカラーパレット。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_096/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_096/service.dart';

void main() {
  group('Pattern 096: DarkModeColor', () {
    test('model toJson and fromJson', () {
      const result = Pattern096Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern096Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern096Service();
      final result = await service.run();
      expect(result, isA<Pattern096Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
