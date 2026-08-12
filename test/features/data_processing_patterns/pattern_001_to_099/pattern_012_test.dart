// Pattern 012: SortCustom - テスト
// カスタムコンパレータによるソート。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_012/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_012/service.dart';

void main() {
  group('Pattern 012: SortCustom', () {
    test('model toJson and fromJson', () {
      const result = Pattern012Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern012Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern012Service();
      final result = await service.run();
      expect(result, isA<Pattern012Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
