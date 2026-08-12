// Pattern 180: ZipUpload - テスト
// ZIP 圧縮してアップロード。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_180/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_180/service.dart';

void main() {
  group('Pattern 180: ZipUpload', () {
    test('model toJson and fromJson', () {
      const result = Pattern180Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern180Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern180Service();
      final result = await service.run();
      expect(result, isA<Pattern180Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
