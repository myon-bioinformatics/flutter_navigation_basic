// Pattern 085: WebSocketSubprotocol - テスト
// WebSocket サブプロトコル指定。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_085/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_085/service.dart';

void main() {
  group('Pattern 085: WebSocketSubprotocol', () {
    test('model toJson and fromJson', () {
      const result = Pattern085Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern085Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern085Service();
      final result = await service.run();
      expect(result, isA<Pattern085Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
