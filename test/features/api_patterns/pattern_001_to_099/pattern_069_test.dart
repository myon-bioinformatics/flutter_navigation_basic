// Pattern 069: WebSocketAuth - テスト
// WebSocket 接続時の認証トークン付与。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_069/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_069/service.dart';

void main() {
  group('Pattern 069: WebSocketAuth', () {
    test('model toJson and fromJson', () {
      const result = Pattern069Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern069Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern069Service();
      final result = await service.run();
      expect(result, isA<Pattern069Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
