// Pattern 026: SortedSet - テスト
// ソート済みセットのデータ構造実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_026/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_026/service.dart';

void main() {
  group('Pattern 026: SortedSet', () {
    test('model toJson and fromJson', () {
      const result = Pattern026Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern026Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern026Service();
      final result = await service.run();
      expect(result, isA<Pattern026Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
