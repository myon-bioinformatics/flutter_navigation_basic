// Pattern 075: DrawerPersistent - テスト
// 常に表示される Persistent Drawer。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_075/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_075/service.dart';

void main() {
  group('Pattern 075: DrawerPersistent', () {
    test('model toJson and fromJson', () {
      const result = Pattern075Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern075Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern075Service();
      final result = await service.run();
      expect(result, isA<Pattern075Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
