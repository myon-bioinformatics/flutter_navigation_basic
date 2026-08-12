// Pattern 197: MultiWindowNav - テスト
// 複数ウィンドウ (デスクトップ) ナビゲーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_197/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_197/service.dart';

void main() {
  group('Pattern 197: MultiWindowNav', () {
    test('model toJson and fromJson', () {
      const result = Pattern197Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern197Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern197Service();
      final result = await service.run();
      expect(result, isA<Pattern197Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
