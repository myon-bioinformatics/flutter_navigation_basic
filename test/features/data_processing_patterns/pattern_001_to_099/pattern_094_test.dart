// Pattern 094: PhoneValidation - テスト
// 電話番号バリデーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_094/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_094/service.dart';

void main() {
  group('Pattern 094: PhoneValidation', () {
    test('model toJson and fromJson', () {
      const result = Pattern094Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern094Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern094Service();
      final result = await service.run();
      expect(result, isA<Pattern094Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
