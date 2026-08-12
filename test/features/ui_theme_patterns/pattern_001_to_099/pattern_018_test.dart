// Pattern 018: Divider - テスト
// Divider と VerticalDivider。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_018/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_018/service.dart';

void main() {
  group('Pattern 018: Divider', () {
    test('model toJson and fromJson', () {
      const result = Pattern018Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern018Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern018Service();
      final result = await service.run();
      expect(result, isA<Pattern018Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
