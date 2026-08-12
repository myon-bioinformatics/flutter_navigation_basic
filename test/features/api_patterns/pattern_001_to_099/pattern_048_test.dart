// Pattern 048: Pkce - テスト
// PKCE フローによる OAuth2 実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_048/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_048/service.dart';

void main() {
  group('Pattern 048: Pkce', () {
    test('model toJson and fromJson', () {
      const result = Pattern048Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern048Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern048Service();
      final result = await service.run();
      expect(result, isA<Pattern048Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
