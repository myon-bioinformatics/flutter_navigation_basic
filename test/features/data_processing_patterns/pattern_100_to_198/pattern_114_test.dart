// Pattern 114: SchemaValidation - テスト
// スキーマ定義によるバリデーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_114/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_114/service.dart';

void main() {
  group('Pattern 114: SchemaValidation', () {
    test('model toJson and fromJson', () {
      const result = Pattern114Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern114Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern114Service();
      final result = await service.run();
      expect(result, isA<Pattern114Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
