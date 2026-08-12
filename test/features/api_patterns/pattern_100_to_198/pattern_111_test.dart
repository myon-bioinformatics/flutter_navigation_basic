// Pattern 111: XmlParse - テスト
// XML 文字列のパース (標準ライブラリ範囲)。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_111/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_111/service.dart';

void main() {
  group('Pattern 111: XmlParse', () {
    test('model toJson and fromJson', () {
      const result = Pattern111Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern111Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern111Service();
      final result = await service.run();
      expect(result, isA<Pattern111Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
