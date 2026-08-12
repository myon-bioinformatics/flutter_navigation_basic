// Pattern 116: SystemBrightness - テスト
// システム輝度に連動するテーマ。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_116/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_116/service.dart';

void main() {
  group('Pattern 116: SystemBrightness', () {
    test('model toJson and fromJson', () {
      const result = Pattern116Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern116Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern116Service();
      final result = await service.run();
      expect(result, isA<Pattern116Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
