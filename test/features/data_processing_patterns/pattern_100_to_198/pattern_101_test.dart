// Pattern 101: CrossField - テスト
// クロスフィールドバリデーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_101/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_101/service.dart';

void main() {
  group('Pattern 101: CrossField', () {
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
