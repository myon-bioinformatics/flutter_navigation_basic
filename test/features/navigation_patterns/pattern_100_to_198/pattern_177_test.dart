// Pattern 177: SearchDelegate - テスト
// SearchDelegate による検索画面。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_177/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_177/service.dart';

void main() {
  group('Pattern 177: SearchDelegate', () {
    test('model toJson and fromJson', () {
      const result = Pattern177Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern177Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern177Service();
      final result = await service.run();
      expect(result, isA<Pattern177Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
