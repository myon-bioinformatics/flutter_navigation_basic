// Pattern 007: PopUntil - テスト
// 指定ルートが見つかるまで Pop を繰り返す。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_007/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_007/service.dart';

void main() {
  group('Pattern 007: PopUntil', () {
    test('model toJson and fromJson', () {
      const result = Pattern007Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern007Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern007Service();
      final result = await service.run();
      expect(result, isA<Pattern007Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
