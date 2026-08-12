// Pattern 066: TabBarFixed - テスト
// 固定幅 TabBar の実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_066/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_066/service.dart';

void main() {
  group('Pattern 066: TabBarFixed', () {
    test('model toJson and fromJson', () {
      const result = Pattern066Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern066Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern066Service();
      final result = await service.run();
      expect(result, isA<Pattern066Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
