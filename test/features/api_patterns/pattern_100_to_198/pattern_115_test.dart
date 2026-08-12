// Pattern 115: JsonNormalize - テスト
// フラット化と正規化処理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_115/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_115/service.dart';

void main() {
  group('Pattern 115: JsonNormalize', () {
    test('model toJson and fromJson', () {
      const result = Pattern115Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern115Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern115Service();
      final result = await service.run();
      expect(result, isA<Pattern115Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
