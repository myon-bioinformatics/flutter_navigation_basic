// Pattern 185: ReduceMotion - テスト
// モーション低減設定の検出と対応。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_185/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_185/service.dart';

void main() {
  group('Pattern 185: ReduceMotion', () {
    test('model toJson and fromJson', () {
      const result = Pattern185Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern185Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern185Service();
      final result = await service.run();
      expect(result, isA<Pattern185Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
