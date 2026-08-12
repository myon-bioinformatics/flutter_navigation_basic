// Pattern 183: Onboarding - テスト
// スプラッシュ→オンボーディング→ホームフロー。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_183/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_183/service.dart';

void main() {
  group('Pattern 183: Onboarding', () {
    test('model toJson and fromJson', () {
      const result = Pattern183Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern183Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern183Service();
      final result = await service.run();
      expect(result, isA<Pattern183Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
