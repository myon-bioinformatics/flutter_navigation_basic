// Pattern 103: ClearStack - テスト
// バックスタック全クリア後に遷移。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_103/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_103/service.dart';

void main() {
  group('Pattern 103: ClearStack', () {
    test('model toJson and fromJson', () {
      const result = Pattern103Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern103Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern103Service();
      final result = await service.run();
      expect(result, isA<Pattern103Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
