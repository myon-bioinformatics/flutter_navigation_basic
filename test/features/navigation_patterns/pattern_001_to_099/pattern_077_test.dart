// Pattern 077: NavigationRail - テスト
// NavigationRail によるサイドナビゲーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_077/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_077/service.dart';

void main() {
  group('Pattern 077: NavigationRail', () {
    test('model toJson and fromJson', () {
      const result = Pattern077Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern077Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern077Service();
      final result = await service.run();
      expect(result, isA<Pattern077Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
