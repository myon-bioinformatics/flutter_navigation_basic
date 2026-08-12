// Pattern 029: Timeout - テスト
// タイムアウト付き HTTP リクエスト基本形。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_029/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_029/service.dart';

void main() {
  group('Pattern 029: Timeout', () {
    test('model toJson and fromJson', () {
      const result = Pattern029Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern029Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern029Service();
      final result = await service.run();
      expect(result, isA<Pattern029Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
