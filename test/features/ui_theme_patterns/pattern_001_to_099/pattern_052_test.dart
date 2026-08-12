// Pattern 052: CupertinoFullscreen - テスト
// CupertinoFullscreenDialogTransition。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_052/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_052/service.dart';

void main() {
  group('Pattern 052: CupertinoFullscreen', () {
    test('model toJson and fromJson', () {
      const result = Pattern052Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern052Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern052Service();
      final result = await service.run();
      expect(result, isA<Pattern052Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
