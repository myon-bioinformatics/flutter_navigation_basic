// Pattern 123: FlexibleLayout - テスト
// Flexible + Expanded によるレイアウト。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_123/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_123/service.dart';

void main() {
  group('Pattern 123: FlexibleLayout', () {
    test('model toJson and fromJson', () {
      const result = Pattern123Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern123Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern123Service();
      final result = await service.run();
      expect(result, isA<Pattern123Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
