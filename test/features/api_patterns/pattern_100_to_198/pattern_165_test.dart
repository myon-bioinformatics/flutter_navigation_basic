// Pattern 165: PrefetchCache - テスト
// 画面遷移前にデータをプリフェッチ。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_165/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_165/service.dart';

void main() {
  group('Pattern 165: PrefetchCache', () {
    test('model toJson and fromJson', () {
      const result = Pattern165Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern165Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern165Service();
      final result = await service.run();
      expect(result, isA<Pattern165Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
