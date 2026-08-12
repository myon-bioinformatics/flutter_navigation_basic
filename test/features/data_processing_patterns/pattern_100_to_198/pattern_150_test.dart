// Pattern 150: AsyncGenerator - テスト
// 非同期ジェネレーター関数の実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_150/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_150/service.dart';

void main() {
  group('Pattern 150: AsyncGenerator', () {
    test('model toJson and fromJson', () {
      const result = Pattern150Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern150Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern150Service();
      final result = await service.run();
      expect(result, isA<Pattern150Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
