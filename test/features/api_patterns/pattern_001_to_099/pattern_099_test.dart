// Pattern 099: JsonPath - テスト
// JSON Path 形式でネスト値を取得。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_099/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_099/service.dart';

void main() {
  group('Pattern 099: JsonPath', () {
    test('model toJson and fromJson', () {
      const result = Pattern099Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern099Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern099Service();
      final result = await service.run();
      expect(result, isA<Pattern099Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
