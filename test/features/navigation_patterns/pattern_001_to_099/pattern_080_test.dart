// Pattern 080: MultiLevelNav - テスト
// 階層型マルチレベルナビゲーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_080/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_080/service.dart';

void main() {
  group('Pattern 080: MultiLevelNav', () {
    test('model toJson and fromJson', () {
      const result = Pattern080Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern080Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern080Service();
      final result = await service.run();
      expect(result, isA<Pattern080Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
