// Pattern 067: AnimatedTheme - テスト
// テーマ切り替えアニメーション実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_067/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_067/service.dart';

void main() {
  group('Pattern 067: AnimatedTheme', () {
    test('model toJson and fromJson', () {
      const result = Pattern067Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern067Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern067Service();
      final result = await service.run();
      expect(result, isA<Pattern067Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
