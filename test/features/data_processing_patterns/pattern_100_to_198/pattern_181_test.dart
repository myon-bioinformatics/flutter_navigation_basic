// Pattern 181: CommandPattern - テスト
// Command パターンによる操作履歴管理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_181/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_181/service.dart';

void main() {
  group('Pattern 181: CommandPattern', () {
    test('model toJson and fromJson', () {
      const result = Pattern181Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern181Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern181Service();
      final result = await service.run();
      expect(result, isA<Pattern181Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
