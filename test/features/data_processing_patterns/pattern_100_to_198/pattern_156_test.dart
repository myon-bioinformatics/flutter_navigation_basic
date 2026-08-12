// Pattern 156: GetxService - テスト
// GetxService による永続サービス実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_156/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_156/service.dart';

void main() {
  group('Pattern 156: GetxService', () {
    test('model toJson and fromJson', () {
      const result = Pattern156Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern156Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern156Service();
      final result = await service.run();
      expect(result, isA<Pattern156Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
