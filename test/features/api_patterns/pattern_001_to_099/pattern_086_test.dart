// Pattern 086: RealTimeList - テスト
// WebSocket でリアルタイム一覧更新。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_086/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_086/service.dart';

void main() {
  group('Pattern 086: RealTimeList', () {
    test('model toJson and fromJson', () {
      const result = Pattern086Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern086Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern086Service();
      final result = await service.run();
      expect(result, isA<Pattern086Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
