// Pattern 088: NetworkAware - テスト
// ネットワーク状態によって画面を切り替え。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_088/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_088/service.dart';

void main() {
  group('Pattern 088: NetworkAware', () {
    test('model toJson and fromJson', () {
      const result = Pattern088Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern088Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern088Service();
      final result = await service.run();
      expect(result, isA<Pattern088Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
