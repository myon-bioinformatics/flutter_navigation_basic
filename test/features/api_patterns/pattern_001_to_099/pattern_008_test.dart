// Pattern 008: JsonParse - テスト
// レスポンス JSON を Dart オブジェクトへ変換。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_008/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_008/service.dart';

void main() {
  group('Pattern 008: JsonParse', () {
    test('model toJson and fromJson', () {
      const result = Pattern008Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern008Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern008Service();
      final result = await service.run();
      expect(result, isA<Pattern008Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
