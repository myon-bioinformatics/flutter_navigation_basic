// Pattern 188: DeeplinkToNested - テスト
// ディープリンクでネスト Navigator の深い画面へ。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_188/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_188/service.dart';

void main() {
  group('Pattern 188: DeeplinkToNested', () {
    test('model toJson and fromJson', () {
      const result = Pattern188Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern188Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern188Service();
      final result = await service.run();
      expect(result, isA<Pattern188Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
