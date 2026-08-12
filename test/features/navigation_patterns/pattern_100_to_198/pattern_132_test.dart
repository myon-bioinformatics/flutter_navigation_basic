// Pattern 132: ChildNavigator - テスト
// 子画面専用の Navigator 実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_132/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_132/service.dart';

void main() {
  group('Pattern 132: ChildNavigator', () {
    test('model toJson and fromJson', () {
      const result = Pattern132Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern132Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern132Service();
      final result = await service.run();
      expect(result, isA<Pattern132Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
