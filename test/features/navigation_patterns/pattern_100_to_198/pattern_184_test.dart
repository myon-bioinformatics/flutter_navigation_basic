// Pattern 184: ProfileSetup - テスト
// 初回プロフィール設定ウィザード。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_184/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_184/service.dart';

void main() {
  group('Pattern 184: ProfileSetup', () {
    test('model toJson and fromJson', () {
      const result = Pattern184Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern184Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern184Service();
      final result = await service.run();
      expect(result, isA<Pattern184Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
