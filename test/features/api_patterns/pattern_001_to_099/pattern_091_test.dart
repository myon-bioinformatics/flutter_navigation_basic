// Pattern 091: JsonBasicParse - テスト
// dart:convert を使った基本 JSON パース。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_091/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_091/service.dart';

void main() {
  group('Pattern 091: JsonBasicParse', () {
    test('model toJson and fromJson', () {
      const result = Pattern091Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern091Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern091Service();
      final result = await service.run();
      expect(result, isA<Pattern091Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
