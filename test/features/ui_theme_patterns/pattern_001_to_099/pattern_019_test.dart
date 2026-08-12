// Pattern 019: ExpansionTile - テスト
// ExpansionTile によるアコーディオン UI。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_019/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_019/service.dart';

void main() {
  group('Pattern 019: ExpansionTile', () {
    test('model toJson and fromJson', () {
      const result = Pattern019Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern019Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern019Service();
      final result = await service.run();
      expect(result, isA<Pattern019Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
