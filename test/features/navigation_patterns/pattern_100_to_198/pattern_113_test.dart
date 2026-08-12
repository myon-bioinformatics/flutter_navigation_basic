// Pattern 113: NavObserver - テスト
// NavigatorObserver でライフサイクルを追跡。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_113/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_113/service.dart';

void main() {
  group('Pattern 113: NavObserver', () {
    test('model toJson and fromJson', () {
      const result = Pattern113Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern113Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern113Service();
      final result = await service.run();
      expect(result, isA<Pattern113Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
