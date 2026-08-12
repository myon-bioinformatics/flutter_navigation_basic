// Pattern 140: Scrollbar - テスト
// カスタムスクロールバー実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_140/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_140/service.dart';

void main() {
  group('Pattern 140: Scrollbar', () {
    test('model toJson and fromJson', () {
      const result = Pattern140Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern140Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern140Service();
      final result = await service.run();
      expect(result, isA<Pattern140Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
