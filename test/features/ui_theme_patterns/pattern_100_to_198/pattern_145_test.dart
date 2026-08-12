// Pattern 145: Stack - テスト
// Stack と Positioned による重ね合わせレイアウト。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_145/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_145/service.dart';

void main() {
  group('Pattern 145: Stack', () {
    test('model toJson and fromJson', () {
      const result = Pattern145Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern145Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern145Service();
      final result = await service.run();
      expect(result, isA<Pattern145Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
