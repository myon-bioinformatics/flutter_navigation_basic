// Pattern 074: DrawerHeader - テスト
// ユーザー情報を表示する DrawerHeader。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_074/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_074/service.dart';

void main() {
  group('Pattern 074: DrawerHeader', () {
    test('model toJson and fromJson', () {
      const result = Pattern074Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern074Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern074Service();
      final result = await service.run();
      expect(result, isA<Pattern074Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
