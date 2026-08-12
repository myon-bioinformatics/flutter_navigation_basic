// Pattern 189: PinAuth - テスト
// PIN入力認証→コンテンツフロー。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_189/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_189/service.dart';

void main() {
  group('Pattern 189: PinAuth', () {
    test('model toJson and fromJson', () {
      const result = Pattern189Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern189Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern189Service();
      final result = await service.run();
      expect(result, isA<Pattern189Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
