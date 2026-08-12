// Pattern 133: DesktopLayout - テスト
// デスクトップ向けサイドバー付きレイアウト。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_133/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_133/service.dart';

void main() {
  group('Pattern 133: DesktopLayout', () {
    test('model toJson and fromJson', () {
      const result = Pattern133Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern133Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern133Service();
      final result = await service.run();
      expect(result, isA<Pattern133Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
