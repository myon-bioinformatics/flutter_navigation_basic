// Pattern 196: LazyLoadImage - テスト
// 遅延ロード画像表示。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_196/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_196/service.dart';

void main() {
  group('Pattern 196: LazyLoadImage', () {
    test('model toJson and fromJson', () {
      const result = Pattern196Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern196Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern196Service();
      final result = await service.run();
      expect(result, isA<Pattern196Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
