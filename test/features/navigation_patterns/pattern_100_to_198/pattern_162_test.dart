// Pattern 162: CustomDialog - テスト
// カスタムデザインの Dialog。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_162/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_162/service.dart';

void main() {
  group('Pattern 162: CustomDialog', () {
    test('model toJson and fromJson', () {
      const result = Pattern162Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern162Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern162Service();
      final result = await service.run();
      expect(result, isA<Pattern162Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
