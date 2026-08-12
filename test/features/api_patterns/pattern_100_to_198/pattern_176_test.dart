// Pattern 176: FileDownload - テスト
// ファイルダウンロード実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_176/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_176/service.dart';

void main() {
  group('Pattern 176: FileDownload', () {
    test('model toJson and fromJson', () {
      const result = Pattern176Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern176Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern176Service();
      final result = await service.run();
      expect(result, isA<Pattern176Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
