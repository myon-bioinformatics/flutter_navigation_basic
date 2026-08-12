// Pattern 013: IndexedStack - テスト
// IndexedStack で状態保持しながら Tab 切り替え。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_013/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_013/service.dart';

void main() {
  group('Pattern 013: IndexedStack', () {
    test('model toJson and fromJson', () {
      const result = Pattern013Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern013Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern013Service();
      final result = await service.run();
      expect(result, isA<Pattern013Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
