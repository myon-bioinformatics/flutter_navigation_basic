// Pattern 105: YamlConfig - テスト
// YAML ファイルから設定を読み込み。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_105/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_105/service.dart';

void main() {
  group('Pattern 105: YamlConfig', () {
    test('model toJson and fromJson', () {
      const result = Pattern105Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern105Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern105Service();
      final result = await service.run();
      expect(result, isA<Pattern105Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
