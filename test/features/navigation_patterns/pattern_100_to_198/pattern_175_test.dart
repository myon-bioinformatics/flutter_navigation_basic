// Pattern 175: ConfirmDialog - テスト
// 確認 Yes/No ダイアログ。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_175/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_175/service.dart';

void main() {
  group('Pattern 175: ConfirmDialog', () {
    test('model toJson and fromJson', () {
      const result = Pattern175Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern175Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern175Service();
      final result = await service.run();
      expect(result, isA<Pattern175Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
