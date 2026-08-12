// Pattern 119: JsonMask - テスト
// JSON の機密フィールドをマスク処理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_119/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_119/service.dart';

void main() {
  group('Pattern 119: JsonMask', () {
    test('model toJson and fromJson', () {
      const result = Pattern119Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern119Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern119Service();
      final result = await service.run();
      expect(result, isA<Pattern119Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
