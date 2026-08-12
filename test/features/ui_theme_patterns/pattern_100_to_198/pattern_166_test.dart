// Pattern 166: FullScreen - テスト
// フルスクリーンモード切り替え。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_166/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_166/service.dart';

void main() {
  group('Pattern 166: FullScreen', () {
    test('model toJson and fromJson', () {
      const result = Pattern166Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern166Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern166Service();
      final result = await service.run();
      expect(result, isA<Pattern166Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
