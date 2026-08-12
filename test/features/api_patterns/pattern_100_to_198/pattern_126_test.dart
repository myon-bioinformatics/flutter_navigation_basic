// Pattern 126: Timeout2 - テスト
// より詳細なタイムアウト制御。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_126/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_126/service.dart';

void main() {
  group('Pattern 126: Timeout2', () {
    test('model toJson and fromJson', () {
      const result = Pattern126Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern126Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern126Service();
      final result = await service.run();
      expect(result, isA<Pattern126Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
