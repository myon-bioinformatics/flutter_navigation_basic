// Pattern 186: MultiStepForm - テスト
// マルチステップフォームのウィザード遷移。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_186/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_186/service.dart';

void main() {
  group('Pattern 186: MultiStepForm', () {
    test('model toJson and fromJson', () {
      const result = Pattern186Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern186Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern186Service();
      final result = await service.run();
      expect(result, isA<Pattern186Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
