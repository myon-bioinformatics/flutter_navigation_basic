// Pattern 058: AdaptiveTextField - テスト
// プラットフォームに応じたテキスト入力。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_058/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_058/service.dart';

void main() {
  group('Pattern 058: AdaptiveTextField', () {
    test('model toJson and fromJson', () {
      const result = Pattern058Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern058Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern058Service();
      final result = await service.run();
      expect(result, isA<Pattern058Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
