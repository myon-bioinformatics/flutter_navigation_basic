// Pattern 173: ColorPicker - テスト
// カラー選択ダイアログ。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_173/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_173/service.dart';

void main() {
  group('Pattern 173: ColorPicker', () {
    test('model toJson and fromJson', () {
      const result = Pattern173Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern173Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern173Service();
      final result = await service.run();
      expect(result, isA<Pattern173Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
