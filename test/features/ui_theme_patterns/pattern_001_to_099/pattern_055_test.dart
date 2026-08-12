// Pattern 055: CupertinoTheme - テスト
// CupertinoThemeData のカスタマイズ。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_055/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_055/service.dart';

void main() {
  group('Pattern 055: CupertinoTheme', () {
    test('model toJson and fromJson', () {
      const result = Pattern055Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern055Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern055Service();
      final result = await service.run();
      expect(result, isA<Pattern055Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
