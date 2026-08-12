// Pattern 130: UserFriendlyError - テスト
// ユーザー向けエラーメッセージの表示。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_130/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_130/service.dart';

void main() {
  group('Pattern 130: UserFriendlyError', () {
    test('model toJson and fromJson', () {
      const result = Pattern130Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern130Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern130Service();
      final result = await service.run();
      expect(result, isA<Pattern130Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
