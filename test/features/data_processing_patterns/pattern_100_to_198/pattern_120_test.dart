// Pattern 120: Zip - テスト
// 複数リストの Zip 結合処理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_120/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_120/service.dart';

void main() {
  group('Pattern 120: Zip', () {
    test('model toJson and fromJson', () {
      const result = Pattern120Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern120Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern120Service();
      final result = await service.run();
      expect(result, isA<Pattern120Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
