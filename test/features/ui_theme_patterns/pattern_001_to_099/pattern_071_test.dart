// Pattern 071: BrandTheme - テスト
// ブランドカラーを反映したテーマ実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_071/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_071/service.dart';

void main() {
  group('Pattern 071: BrandTheme', () {
    test('model toJson and fromJson', () {
      const result = Pattern071Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern071Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern071Service();
      final result = await service.run();
      expect(result, isA<Pattern071Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
