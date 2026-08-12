// Pattern 164: DesktopIcon - テスト
// デスクトップアプリアイコン設定 (擬似)。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_164/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_164/service.dart';

void main() {
  group('Pattern 164: DesktopIcon', () {
    test('model toJson and fromJson', () {
      const result = Pattern164Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern164Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern164Service();
      final result = await service.run();
      expect(result, isA<Pattern164Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
