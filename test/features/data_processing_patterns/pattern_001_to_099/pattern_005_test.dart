// Pattern 005: SearchBasic - テスト
// テキスト検索によるリストフィルタリング。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_005/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_005/service.dart';

void main() {
  group('Pattern 005: SearchBasic', () {
    test('model toJson and fromJson', () {
      const result = Pattern005Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern005Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern005Service();
      final result = await service.run();
      expect(result, isA<Pattern005Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
