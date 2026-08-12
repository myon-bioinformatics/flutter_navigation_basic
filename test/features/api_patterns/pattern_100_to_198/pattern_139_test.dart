// Pattern 139: PartialSuccess - テスト
// 一部成功レスポンスの処理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_139/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_139/service.dart';

void main() {
  group('Pattern 139: PartialSuccess', () {
    test('model toJson and fromJson', () {
      const result = Pattern139Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern139Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern139Service();
      final result = await service.run();
      expect(result, isA<Pattern139Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
