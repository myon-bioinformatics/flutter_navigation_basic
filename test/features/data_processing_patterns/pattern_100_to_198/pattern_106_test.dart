// Pattern 106: CurrencyConvert - テスト
// 通貨変換処理 (擬似実装)。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_106/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_106/service.dart';

void main() {
  group('Pattern 106: CurrencyConvert', () {
    test('model toJson and fromJson', () {
      const result = Pattern106Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern106Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern106Service();
      final result = await service.run();
      expect(result, isA<Pattern106Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
