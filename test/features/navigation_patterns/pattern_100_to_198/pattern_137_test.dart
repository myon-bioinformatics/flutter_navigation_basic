// Pattern 137: SidePanelNav - テスト
// サイドパネル専用 Navigator。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_137/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_137/service.dart';

void main() {
  group('Pattern 137: SidePanelNav', () {
    test('model toJson and fromJson', () {
      const result = Pattern137Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern137Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern137Service();
      final result = await service.run();
      expect(result, isA<Pattern137Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
