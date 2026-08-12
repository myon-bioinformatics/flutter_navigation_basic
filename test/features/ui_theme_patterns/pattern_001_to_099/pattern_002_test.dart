// Pattern 002: ElevatedButton - テスト
// ElevatedButton のスタイルバリエーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_002/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_002/service.dart';

void main() {
  group('Pattern 002: ElevatedButton', () {
    test('model toJson and fromJson', () {
      const result = Pattern002Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern002Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern002Service();
      final result = await service.run();
      expect(result, isA<Pattern002Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
