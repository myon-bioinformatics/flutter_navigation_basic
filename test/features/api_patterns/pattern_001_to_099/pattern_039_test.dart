// Pattern 039: OAuth2ClientCred - テスト
// OAuth2 クライアント認証情報フロー。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_039/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_039/service.dart';

void main() {
  group('Pattern 039: OAuth2ClientCred', () {
    test('model toJson and fromJson', () {
      const result = Pattern039Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern039Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern039Service();
      final result = await service.run();
      expect(result, isA<Pattern039Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
