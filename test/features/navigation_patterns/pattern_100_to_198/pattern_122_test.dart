// Pattern 122: NestedNavTab - テスト
// TabBar + ネスト Navigator の組み合わせ。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_122/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_122/service.dart';

void main() {
  group('Pattern 122: NestedNavTab', () {
    test('model toJson and fromJson', () {
      const result = Pattern122Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern122Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern122Service();
      final result = await service.run();
      expect(result, isA<Pattern122Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
