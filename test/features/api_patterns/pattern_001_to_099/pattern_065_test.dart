// Pattern 065: WebSocketJson - テスト
// WebSocket で JSON メッセージを送受信。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_065/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_065/service.dart';

void main() {
  group('Pattern 065: WebSocketJson', () {
    test('model toJson and fromJson', () {
      const result = Pattern065Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern065Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern065Service();
      final result = await service.run();
      expect(result, isA<Pattern065Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
