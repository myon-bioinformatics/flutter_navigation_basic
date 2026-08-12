// Pattern 102: JsonlStream - テスト
// JSONL をストリームとして処理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_102/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_102/service.dart';

void main() {
  group('Pattern 102: JsonlStream', () {
    test('model toJson and fromJson', () {
      const result = Pattern102Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern102Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern102Service();
      final result = await service.run();
      expect(result, isA<Pattern102Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
