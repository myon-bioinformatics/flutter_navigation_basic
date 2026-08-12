// Pattern 001: HttpGet - テスト
// 基本的な HTTP GET リクエスト実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_001/model.dart';

void main() {
  group('Pattern 001: HttpGet', () {
    test('model toJson and fromJson round-trips', () {
      const result = Pattern001Result(
        message: 'GET https://example.com → 200',
        statusCode: 200,
        body: {'url': 'https://example.com'},
      );
      final json = result.toJson();
      expect(json['message'], contains('200'));
      expect(json['statusCode'], equals(200));
      final restored = Pattern001Result.fromJson(json);
      expect(restored.message, equals(result.message));
      expect(restored.statusCode, equals(200));
    });

    test('model defaults', () {
      const result = Pattern001Result(message: 'test');
      expect(result.statusCode, equals(200));
      expect(result.body, isEmpty);
    });

    test('fromJson handles missing optional fields', () {
      final result =
          Pattern001Result.fromJson({'message': 'hello'});
      expect(result.statusCode, equals(200));
      expect(result.body, isEmpty);
    });
  });
}
