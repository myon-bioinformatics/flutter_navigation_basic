// Pattern 009: PushWithArguments - テスト
// 引数を渡して画面遷移する。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_009/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_009/service.dart';

void main() {
  group('Pattern 009: PushWithArguments', () {
    test('model toJson and fromJson', () {
      const result = Pattern009Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern009Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern009Service();
      final result = await service.run();
      expect(result, isA<Pattern009Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
