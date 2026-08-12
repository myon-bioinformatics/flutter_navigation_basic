// Pattern 150: ErrorChain - テスト
// エラーチェーンによる根本原因の追跡。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_150/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_150/service.dart';

void main() {
  group('Pattern 150: ErrorChain', () {
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
