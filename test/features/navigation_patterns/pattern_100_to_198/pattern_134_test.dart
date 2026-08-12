// Pattern 134: NavigatorKey - テスト
// 特定 Navigator を操作するキー管理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_134/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_134/service.dart';

void main() {
  group('Pattern 134: NavigatorKey', () {
    test('model toJson and fromJson', () {
      const result = Pattern134Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern134Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern134Service();
      final result = await service.run();
      expect(result, isA<Pattern134Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
