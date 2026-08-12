// Pattern 148: CustomSlide - テスト
// カスタムスライド方向の遷移アニメーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_148/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_148/service.dart';

void main() {
  group('Pattern 148: CustomSlide', () {
    test('model toJson and fromJson', () {
      const result = Pattern148Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern148Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern148Service();
      final result = await service.run();
      expect(result, isA<Pattern148Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
