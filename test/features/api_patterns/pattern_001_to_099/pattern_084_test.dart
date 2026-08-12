// Pattern 084: WebSocketCompress - テスト
// WebSocket per-message 圧縮対応。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_084/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_084/service.dart';

void main() {
  group('Pattern 084: WebSocketCompress', () {
    test('model toJson and fromJson', () {
      const result = Pattern084Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern084Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern084Service();
      final result = await service.run();
      expect(result, isA<Pattern084Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
