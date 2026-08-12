// Pattern 037: PullRefresh - テスト
// プルリフレッシュ (更新) 実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_037/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_037/service.dart';

void main() {
  group('Pattern 037: PullRefresh', () {
    test('model toJson and fromJson', () {
      const result = Pattern037Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern037Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern037Service();
      final result = await service.run();
      expect(result, isA<Pattern037Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
