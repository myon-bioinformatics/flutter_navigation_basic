// Pattern 008: Card - テスト
// Card ウィジェットのスタイルバリエーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_008/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_008/service.dart';

void main() {
  group('Pattern 008: Card', () {
    test('model toJson and fromJson', () {
      const result = Pattern008Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern008Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern008Service();
      final result = await service.run();
      expect(result, isA<Pattern008Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
