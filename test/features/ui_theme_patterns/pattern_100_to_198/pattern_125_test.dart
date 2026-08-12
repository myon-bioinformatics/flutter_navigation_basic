// Pattern 125: WrapLayout - テスト
// Wrap による折り返しレイアウト。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_125/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_125/service.dart';

void main() {
  group('Pattern 125: WrapLayout', () {
    test('model toJson and fromJson', () {
      const result = Pattern125Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern125Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern125Service();
      final result = await service.run();
      expect(result, isA<Pattern125Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
