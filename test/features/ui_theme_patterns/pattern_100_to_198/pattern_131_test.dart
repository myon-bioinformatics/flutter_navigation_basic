// Pattern 131: OrientationLayout - テスト
// 縦横に応じたレイアウト切り替え。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_131/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_131/service.dart';

void main() {
  group('Pattern 131: OrientationLayout', () {
    test('model toJson and fromJson', () {
      const result = Pattern131Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern131Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern131Service();
      final result = await service.run();
      expect(result, isA<Pattern131Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
