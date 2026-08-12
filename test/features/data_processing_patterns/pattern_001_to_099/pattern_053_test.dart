// Pattern 053: Reorderable - テスト
// 並び替え可能なリスト実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_053/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_053/service.dart';

void main() {
  group('Pattern 053: Reorderable', () {
    test('model toJson and fromJson', () {
      const result = Pattern053Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern053Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern053Service();
      final result = await service.run();
      expect(result, isA<Pattern053Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
