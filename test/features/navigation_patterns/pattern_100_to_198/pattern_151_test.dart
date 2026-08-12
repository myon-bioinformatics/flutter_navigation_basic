// Pattern 151: CurveAnimation - テスト
// Curves を使ったイージング制御。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_151/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_151/service.dart';

void main() {
  group('Pattern 151: CurveAnimation', () {
    test('model toJson and fromJson', () {
      const result = Pattern151Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern151Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern151Service();
      final result = await service.run();
      expect(result, isA<Pattern151Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
