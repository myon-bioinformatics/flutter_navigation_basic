// Pattern 027: NamedRouteNested - テスト
// 名前付きルートのネスト構造実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_027/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_027/service.dart';

void main() {
  group('Pattern 027: NamedRouteNested', () {
    test('model toJson and fromJson', () {
      const result = Pattern027Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern027Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern027Service();
      final result = await service.run();
      expect(result, isA<Pattern027Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
