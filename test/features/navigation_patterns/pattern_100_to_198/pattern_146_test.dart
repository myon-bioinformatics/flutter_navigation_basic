// Pattern 146: AnimatedSwitcher - テスト
// AnimatedSwitcher によるウィジェット切り替え。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_146/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_146/service.dart';

void main() {
  group('Pattern 146: AnimatedSwitcher', () {
    test('model toJson and fromJson', () {
      const result = Pattern146Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern146Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern146Service();
      final result = await service.run();
      expect(result, isA<Pattern146Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
