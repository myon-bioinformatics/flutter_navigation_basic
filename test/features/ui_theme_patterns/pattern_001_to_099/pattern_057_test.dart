// Pattern 057: PlatformDetect - テスト
// 実行プラットフォームの検出と分岐。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_057/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_057/service.dart';

void main() {
  group('Pattern 057: PlatformDetect', () {
    test('model toJson and fromJson', () {
      const result = Pattern057Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern057Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern057Service();
      final result = await service.run();
      expect(result, isA<Pattern057Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
