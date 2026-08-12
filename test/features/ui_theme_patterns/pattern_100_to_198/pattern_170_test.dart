// Pattern 170: GestureScale - テスト
// デスクトップ向けピンチズーム対応。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_170/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_170/service.dart';

void main() {
  group('Pattern 170: GestureScale', () {
    test('model toJson and fromJson', () {
      const result = Pattern170Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern170Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern170Service();
      final result = await service.run();
      expect(result, isA<Pattern170Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
