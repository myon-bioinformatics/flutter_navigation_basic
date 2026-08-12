// Pattern 076: DrawerModal - テスト
// モーダル形式の Drawer。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_076/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_076/service.dart';

void main() {
  group('Pattern 076: DrawerModal', () {
    test('model toJson and fromJson', () {
      const result = Pattern076Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern076Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern076Service();
      final result = await service.run();
      expect(result, isA<Pattern076Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
