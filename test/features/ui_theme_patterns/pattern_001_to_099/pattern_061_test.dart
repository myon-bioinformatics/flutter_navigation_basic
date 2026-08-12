// Pattern 061: CustomThemeBasic - テスト
// ThemeData.copyWith によるテーマ拡張。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_061/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_061/service.dart';

void main() {
  group('Pattern 061: CustomThemeBasic', () {
    test('model toJson and fromJson', () {
      const result = Pattern061Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern061Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern061Service();
      final result = await service.run();
      expect(result, isA<Pattern061Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
