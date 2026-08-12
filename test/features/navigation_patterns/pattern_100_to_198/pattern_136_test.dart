// Pattern 136: OverlayNavigator - テスト
// Overlay を使った独立ナビゲーション層。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_136/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_136/service.dart';

void main() {
  group('Pattern 136: OverlayNavigator', () {
    test('model toJson and fromJson', () {
      const result = Pattern136Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern136Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern136Service();
      final result = await service.run();
      expect(result, isA<Pattern136Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
