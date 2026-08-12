// Pattern 022: HttpOptions - テスト
// OPTIONS リクエストで許可メソッド確認。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_022/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_022/service.dart';

void main() {
  group('Pattern 022: HttpOptions', () {
    test('model toJson and fromJson', () {
      const result = Pattern022Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern022Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern022Service();
      final result = await service.run();
      expect(result, isA<Pattern022Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
