// Pattern 194: Base64Image - テスト
// Base64 エンコード画像の表示。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_194/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_194/service.dart';

void main() {
  group('Pattern 194: Base64Image', () {
    test('model toJson and fromJson', () {
      const result = Pattern194Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern194Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern194Service();
      final result = await service.run();
      expect(result, isA<Pattern194Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
