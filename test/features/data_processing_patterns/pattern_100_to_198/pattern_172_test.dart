// Pattern 172: ReorderList - テスト
// ReorderableListView による並び替え。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_172/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_172/service.dart';

void main() {
  group('Pattern 172: ReorderList', () {
    test('model toJson and fromJson', () {
      const result = Pattern172Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern172Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern172Service();
      final result = await service.run();
      expect(result, isA<Pattern172Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
