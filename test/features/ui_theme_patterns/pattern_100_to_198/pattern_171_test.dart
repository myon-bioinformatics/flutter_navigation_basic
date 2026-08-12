// Pattern 171: ScrollPhysics - テスト
// プラットフォーム別スクロール物理設定。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_171/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_171/service.dart';

void main() {
  group('Pattern 171: ScrollPhysics', () {
    test('model toJson and fromJson', () {
      const result = Pattern171Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern171Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern171Service();
      final result = await service.run();
      expect(result, isA<Pattern171Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
