// Pattern 070: TabBarNested - テスト
// ネストされた TabBar 構造。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_070/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_070/service.dart';

void main() {
  group('Pattern 070: TabBarNested', () {
    test('model toJson and fromJson', () {
      const result = Pattern070Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern070Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern070Service();
      final result = await service.run();
      expect(result, isA<Pattern070Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
