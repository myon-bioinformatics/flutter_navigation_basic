// Pattern 040: ApiKeyQuery - テスト
// API Key をクエリパラメータで送信。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_040/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_040/service.dart';

void main() {
  group('Pattern 040: ApiKeyQuery', () {
    test('model toJson and fromJson', () {
      const result = Pattern040Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern040Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern040Service();
      final result = await service.run();
      expect(result, isA<Pattern040Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
