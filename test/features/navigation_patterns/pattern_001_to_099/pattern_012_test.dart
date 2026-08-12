// Pattern 012: NestedNavigator - テスト
// 子 Navigator を持つ Nested ナビゲーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_012/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_012/service.dart';

void main() {
  group('Pattern 012: NestedNavigator', () {
    test('model toJson and fromJson', () {
      const result = Pattern012Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern012Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern012Service();
      final result = await service.run();
      expect(result, isA<Pattern012Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
