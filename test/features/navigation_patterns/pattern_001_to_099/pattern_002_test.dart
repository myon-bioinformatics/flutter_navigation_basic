// Pattern 002: BasicPop - テスト
// スタックから現在画面を取り除く Pop 遷移。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_002/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_002/service.dart';

void main() {
  group('Pattern 002: BasicPop', () {
    test('model toJson and fromJson', () {
      const result = Pattern002Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern002Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern002Service();
      final result = await service.run();
      expect(result, isA<Pattern002Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
