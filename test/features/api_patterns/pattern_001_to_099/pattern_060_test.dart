// Pattern 060: LogoutRevoke - テスト
// ログアウト + トークン失効実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_060/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_060/service.dart';

void main() {
  group('Pattern 060: LogoutRevoke', () {
    test('model toJson and fromJson', () {
      const result = Pattern060Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern060Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern060Service();
      final result = await service.run();
      expect(result, isA<Pattern060Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
