// Pattern 129: ShellRoute - テスト
// ShellRoute を使ったレイアウト共有。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_129/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_129/service.dart';

void main() {
  group('Pattern 129: ShellRoute', () {
    test('model toJson and fromJson', () {
      const result = Pattern129Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern129Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern129Service();
      final result = await service.run();
      expect(result, isA<Pattern129Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
