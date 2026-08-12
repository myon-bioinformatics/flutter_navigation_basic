// Pattern 107: UnitConvert - テスト
// 単位変換処理 (長さ、重量等)。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_107/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_107/service.dart';

void main() {
  group('Pattern 107: UnitConvert', () {
    test('model toJson and fromJson', () {
      const result = Pattern107Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern107Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern107Service();
      final result = await service.run();
      expect(result, isA<Pattern107Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
