// Pattern 081: WebSocketPool - テスト
// WebSocket 接続プール管理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_081/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_081/service.dart';

void main() {
  group('Pattern 081: WebSocketPool', () {
    test('model toJson and fromJson', () {
      const result = Pattern081Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern081Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern081Service();
      final result = await service.run();
      expect(result, isA<Pattern081Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
