// Pattern 109: CsvParse - テスト
// CSV 形式のパースと DataFrame 風処理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_109/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_109/service.dart';

void main() {
  group('Pattern 109: CsvParse', () {
    test('model toJson and fromJson', () {
      const result = Pattern109Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern109Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern109Service();
      final result = await service.run();
      expect(result, isA<Pattern109Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
