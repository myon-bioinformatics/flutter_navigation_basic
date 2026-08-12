// Pattern 193: AudioEmbed - テスト
// 音声 URL の埋め込み再生 (擬似実装)。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_193/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_193/service.dart';

void main() {
  group('Pattern 193: AudioEmbed', () {
    test('model toJson and fromJson', () {
      const result = Pattern193Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern193Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern193Service();
      final result = await service.run();
      expect(result, isA<Pattern193Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
