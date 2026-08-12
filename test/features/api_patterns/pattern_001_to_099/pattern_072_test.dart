// Pattern 072: SseReconnect - テスト
// SSE 切断時の自動再接続。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_072/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_072/service.dart';

void main() {
  group('Pattern 072: SseReconnect', () {
    test('model toJson and fromJson', () {
      const result = Pattern072Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern072Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern072Service();
      final result = await service.run();
      expect(result, isA<Pattern072Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
