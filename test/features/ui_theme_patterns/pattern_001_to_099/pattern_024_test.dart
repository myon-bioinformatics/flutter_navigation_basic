// Pattern 024: SegmentedButton - テスト
// SegmentedButton (M3) の実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_024/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_024/service.dart';

void main() {
  group('Pattern 024: SegmentedButton', () {
    test('model toJson and fromJson', () {
      const result = Pattern024Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern024Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern024Service();
      final result = await service.run();
      expect(result, isA<Pattern024Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
