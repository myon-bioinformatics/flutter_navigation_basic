// Pattern 087: NotificationWs - テスト
// WebSocket によるプッシュ通知受信。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_087/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_087/service.dart';

void main() {
  group('Pattern 087: NotificationWs', () {
    test('model toJson and fromJson', () {
      const result = Pattern087Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern087Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern087Service();
      final result = await service.run();
      expect(result, isA<Pattern087Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
