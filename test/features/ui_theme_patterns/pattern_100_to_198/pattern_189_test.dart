// Pattern 189: TouchTarget - テスト
// 最小タッチターゲットサイズの確保。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_189/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_189/service.dart';

void main() {
  group('Pattern 189: TouchTarget', () {
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
