// Pattern 097: JsonDiff - テスト
// 2つの JSON オブジェクトの差分比較。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_097/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_097/service.dart';

void main() {
  group('Pattern 097: JsonDiff', () {
    test('model toJson and fromJson', () {
      const result = Pattern097Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern097Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern097Service();
      final result = await service.run();
      expect(result, isA<Pattern097Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
