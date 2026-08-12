// Pattern 141: AnimatedPageRoute - テスト
// カスタム PageRoute アニメーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_141/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_141/service.dart';

void main() {
  group('Pattern 141: AnimatedPageRoute', () {
    test('model toJson and fromJson', () {
      const result = Pattern141Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern141Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern141Service();
      final result = await service.run();
      expect(result, isA<Pattern141Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
