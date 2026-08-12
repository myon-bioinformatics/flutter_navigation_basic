// Pattern 104: Sepia - テスト
// セピア調テーマ実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_104/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_104/service.dart';

void main() {
  group('Pattern 104: Sepia', () {
    test('model toJson and fromJson', () {
      const result = Pattern104Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern104Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern104Service();
      final result = await service.run();
      expect(result, isA<Pattern104Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
