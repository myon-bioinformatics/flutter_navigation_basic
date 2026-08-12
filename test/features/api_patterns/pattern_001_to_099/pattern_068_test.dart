// Pattern 068: WebSocketBroadcast - テスト
// ブロードキャストメッセージの受信。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_068/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_068/service.dart';

void main() {
  group('Pattern 068: WebSocketBroadcast', () {
    test('model toJson and fromJson', () {
      const result = Pattern068Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern068Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern068Service();
      final result = await service.run();
      expect(result, isA<Pattern068Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
