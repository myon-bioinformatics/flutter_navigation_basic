// Pattern 073: SseEventType - テスト
// SSE 名前付きイベントの処理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_073/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_073/service.dart';

void main() {
  group('Pattern 073: SseEventType', () {
    test('model toJson and fromJson', () {
      const result = Pattern073Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern073Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern073Service();
      final result = await service.run();
      expect(result, isA<Pattern073Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
