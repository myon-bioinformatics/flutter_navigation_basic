// Pattern 089: PermissionGuard - テスト
// 権限確認後に画面遷移。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_089/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_089/service.dart';

void main() {
  group('Pattern 089: PermissionGuard', () {
    test('model toJson and fromJson', () {
      const result = Pattern089Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern089Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern089Service();
      final result = await service.run();
      expect(result, isA<Pattern089Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
