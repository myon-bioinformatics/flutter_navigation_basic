// Pattern 088: PresenceWs - テスト
// WebSocket でオンライン状態管理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_088/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_088/service.dart';

void main() {
  group('Pattern 088: PresenceWs', () {
    test('model toJson and fromJson', () {
      const result = Pattern088Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern088Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern088Service();
      final result = await service.run();
      expect(result, isA<Pattern088Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
