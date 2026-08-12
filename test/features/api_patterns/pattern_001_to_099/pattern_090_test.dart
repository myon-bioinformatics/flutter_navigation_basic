// Pattern 090: LiveFeed - テスト
// SSE によるライブフィード表示。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_090/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_090/service.dart';

void main() {
  group('Pattern 090: LiveFeed', () {
    test('model toJson and fromJson', () {
      const result = Pattern090Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern090Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern090Service();
      final result = await service.run();
      expect(result, isA<Pattern090Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
