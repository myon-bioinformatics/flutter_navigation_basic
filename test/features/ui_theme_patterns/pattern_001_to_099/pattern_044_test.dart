// Pattern 044: CupertinoFormRow - テスト
// CupertinoFormRow の実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_044/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_044/service.dart';

void main() {
  group('Pattern 044: CupertinoFormRow', () {
    test('model toJson and fromJson', () {
      const result = Pattern044Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern044Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern044Service();
      final result = await service.run();
      expect(result, isA<Pattern044Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
