// Pattern 187: InvertColor - テスト
// 色反転モード対応。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_187/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_187/service.dart';

void main() {
  group('Pattern 187: InvertColor', () {
    test('model toJson and fromJson', () {
      const result = Pattern187Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern187Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern187Service();
      final result = await service.run();
      expect(result, isA<Pattern187Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
