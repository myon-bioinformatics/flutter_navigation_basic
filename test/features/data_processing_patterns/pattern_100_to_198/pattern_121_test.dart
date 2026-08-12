// Pattern 121: FutureBasic - テスト
// 基本的な Future と async/await 実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_121/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_121/service.dart';

void main() {
  group('Pattern 121: FutureBasic', () {
    test('model toJson and fromJson', () {
      const result = Pattern121Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern121Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern121Service();
      final result = await service.run();
      expect(result, isA<Pattern121Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
