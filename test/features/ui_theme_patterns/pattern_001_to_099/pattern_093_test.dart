// Pattern 093: ManualDarkMode - テスト
// ユーザー手動でのダークモード切り替え。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_093/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_093/service.dart';

void main() {
  group('Pattern 093: ManualDarkMode', () {
    test('model toJson and fromJson', () {
      const result = Pattern093Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern093Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern093Service();
      final result = await service.run();
      expect(result, isA<Pattern093Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
