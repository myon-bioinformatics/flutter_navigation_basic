// Pattern 176: FormDialog - テスト
// フォーム入力ダイアログ。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_176/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_176/service.dart';

void main() {
  group('Pattern 176: FormDialog', () {
    test('model toJson and fromJson', () {
      const result = Pattern176Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern176Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern176Service();
      final result = await service.run();
      expect(result, isA<Pattern176Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
