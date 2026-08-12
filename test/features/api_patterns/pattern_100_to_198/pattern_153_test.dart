// Pattern 153: LastModified - テスト
// Last-Modified を使ったキャッシュ制御。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_153/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_153/service.dart';

void main() {
  group('Pattern 153: LastModified', () {
    test('model toJson and fromJson', () {
      const result = Pattern153Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern153Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern153Service();
      final result = await service.run();
      expect(result, isA<Pattern153Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
