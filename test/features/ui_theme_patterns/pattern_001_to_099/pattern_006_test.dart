// Pattern 006: FloatingActionButton - テスト
// FAB の配置とスタイル。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_006/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_006/service.dart';

void main() {
  group('Pattern 006: FloatingActionButton', () {
    test('model toJson and fromJson', () {
      const result = Pattern006Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern006Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern006Service();
      final result = await service.run();
      expect(result, isA<Pattern006Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
