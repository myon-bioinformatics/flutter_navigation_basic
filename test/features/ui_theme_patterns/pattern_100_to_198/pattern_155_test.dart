// Pattern 155: WebContextMenu - テスト
// Web 向けコンテキストメニュー無効化。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_155/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_155/service.dart';

void main() {
  group('Pattern 155: WebContextMenu', () {
    test('model toJson and fromJson', () {
      const result = Pattern155Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern155Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern155Service();
      final result = await service.run();
      expect(result, isA<Pattern155Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
