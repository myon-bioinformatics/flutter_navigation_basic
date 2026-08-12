// Pattern 025: Accept - テスト
// Accept ヘッダーによるレスポンス形式指定。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_025/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_025/service.dart';

void main() {
  group('Pattern 025: Accept', () {
    test('model toJson and fromJson', () {
      const result = Pattern025Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern025Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern025Service();
      final result = await service.run();
      expect(result, isA<Pattern025Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
