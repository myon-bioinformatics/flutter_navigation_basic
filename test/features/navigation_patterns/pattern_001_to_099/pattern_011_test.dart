// Pattern 011: WillPopScope - テスト
// WillPopScope で遷移キャンセルを制御。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_011/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_011/service.dart';

void main() {
  group('Pattern 011: WillPopScope', () {
    test('model toJson and fromJson', () {
      const result = Pattern011Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern011Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern011Service();
      final result = await service.run();
      expect(result, isA<Pattern011Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
