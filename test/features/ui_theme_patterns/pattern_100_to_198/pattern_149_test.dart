// Pattern 149: AdaptiveFont - テスト
// 画面サイズに応じたフォントサイズ調整。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_149/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_149/service.dart';

void main() {
  group('Pattern 149: AdaptiveFont', () {
    test('model toJson and fromJson', () {
      const result = Pattern149Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern149Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern149Service();
      final result = await service.run();
      expect(result, isA<Pattern149Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
