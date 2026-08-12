// Pattern 108: BackInterceptor - テスト
// バック操作を横取りして処理を挟む。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_108/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_108/service.dart';

void main() {
  group('Pattern 108: BackInterceptor', () {
    test('model toJson and fromJson', () {
      const result = Pattern108Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern108Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern108Service();
      final result = await service.run();
      expect(result, isA<Pattern108Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
