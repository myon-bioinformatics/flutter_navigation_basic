// Pattern 159: WaveTransition - テスト
// 波形アニメーション付き遷移。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_159/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_159/service.dart';

void main() {
  group('Pattern 159: WaveTransition', () {
    test('model toJson and fromJson', () {
      const result = Pattern159Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern159Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern159Service();
      final result = await service.run();
      expect(result, isA<Pattern159Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
