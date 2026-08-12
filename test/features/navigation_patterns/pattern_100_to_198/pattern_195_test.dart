// Pattern 195: NotificationNav - テスト
// 通知タップ→詳細画面への遷移。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_195/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_195/service.dart';

void main() {
  group('Pattern 195: NotificationNav', () {
    test('model toJson and fromJson', () {
      const result = Pattern195Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern195Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern195Service();
      final result = await service.run();
      expect(result, isA<Pattern195Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
