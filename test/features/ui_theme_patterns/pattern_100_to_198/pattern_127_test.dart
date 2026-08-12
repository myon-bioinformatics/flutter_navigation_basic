// Pattern 127: AspectRatio - テスト
// AspectRatio によるアスペクト比固定。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_127/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_127/service.dart';

void main() {
  group('Pattern 127: AspectRatio', () {
    test('model toJson and fromJson', () {
      const result = Pattern127Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern127Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern127Service();
      final result = await service.run();
      expect(result, isA<Pattern127Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
