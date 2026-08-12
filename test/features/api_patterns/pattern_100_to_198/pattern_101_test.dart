// Pattern 101: JsonlWrite - テスト
// JSONL 形式への書き込み実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_101/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_101/service.dart';

void main() {
  group('Pattern 101: JsonlWrite', () {
    test('model toJson and fromJson', () {
      const result = Pattern101Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern101Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern101Service();
      final result = await service.run();
      expect(result, isA<Pattern101Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
