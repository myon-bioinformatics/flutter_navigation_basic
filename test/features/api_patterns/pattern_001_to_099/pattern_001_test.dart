// Pattern 001: HttpGet - テスト
// 基本的な HTTP GET リクエスト実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_001/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_001/service.dart';

void main() {
  group('Pattern 001: HttpGet', () {
    test('model toJson and fromJson', () {
      const result = Pattern001Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern001Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern001Service();
      final result = await service.run();
      expect(result, isA<Pattern001Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
