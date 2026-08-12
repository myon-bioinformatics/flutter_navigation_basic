// Pattern 022: Tokenize - テスト
// テキストトークナイズ処理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_022/model.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_022/service.dart';

void main() {
  group('Pattern 022: Tokenize', () {
    test('model toJson and fromJson', () {
      const result = Pattern022Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern022Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern022Service();
      final result = await service.run();
      expect(result, isA<Pattern022Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
