// Pattern 131: ValidationError - テスト
// バリデーション失敗エラーの処理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_131/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_131/service.dart';

void main() {
  group('Pattern 131: ValidationError', () {
    test('model toJson and fromJson', () {
      const result = Pattern131Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern131Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern131Service();
      final result = await service.run();
      expect(result, isA<Pattern131Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
