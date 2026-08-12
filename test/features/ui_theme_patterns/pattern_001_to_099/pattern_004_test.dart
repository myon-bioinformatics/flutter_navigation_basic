// Pattern 004: OutlinedButton - テスト
// OutlinedButton のスタイル実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_004/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_004/service.dart';

void main() {
  group('Pattern 004: OutlinedButton', () {
    test('model toJson and fromJson', () {
      const result = Pattern004Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern004Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern004Service();
      final result = await service.run();
      expect(result, isA<Pattern004Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
