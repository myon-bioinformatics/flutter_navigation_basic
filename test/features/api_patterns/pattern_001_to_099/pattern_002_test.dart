// Pattern 002: HttpPost - テスト
// JSON ボディ付き HTTP POST リクエスト。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_002/model.dart';

void main() {
  group('Pattern 002: HttpPost', () {
    test('model toJson and fromJson round-trips', () {
      const result = Pattern002Result(
        message: 'POST https://example.com → 200',
        statusCode: 200,
        echo: {'title': 'foo'},
      );
      final json = result.toJson();
      expect(json['statusCode'], equals(200));
      final restored = Pattern002Result.fromJson(json);
      expect(restored.message, equals(result.message));
      expect(restored.echo['title'], equals('foo'));
    });

    test('model defaults', () {
      const result = Pattern002Result(message: 'test');
      expect(result.statusCode, equals(200));
      expect(result.echo, isEmpty);
    });
  });
}
