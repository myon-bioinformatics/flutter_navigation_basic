// Pattern 102: SanitizeInput - テスト
// XSS/SQLインジェクション防止の入力サニタイズ。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_102/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_102/service.dart';

void main() {
  group('Pattern 102: SanitizeInput', () {
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
