// Pattern 117: JsonEncoding - テスト
// 文字エンコーディング対応 JSON 処理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_117/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_117/service.dart';

void main() {
  group('Pattern 117: JsonEncoding', () {
    test('model toJson and fromJson', () {
      const result = Pattern117Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern117Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern117Service();
      final result = await service.run();
      expect(result, isA<Pattern117Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
