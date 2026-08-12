// Pattern 118: NavigationStack - テスト
// 画面スタックをリスト操作でコントロール。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_118/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_118/service.dart';

void main() {
  group('Pattern 118: NavigationStack', () {
    test('model toJson and fromJson', () {
      const result = Pattern118Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern118Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern118Service();
      final result = await service.run();
      expect(result, isA<Pattern118Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
