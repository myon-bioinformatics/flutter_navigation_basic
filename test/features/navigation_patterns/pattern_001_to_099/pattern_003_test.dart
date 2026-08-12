// Pattern 003: BasicReplace - テスト
// 現在画面を新しい画面に置き換える Replace 遷移。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_003/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_003/service.dart';

void main() {
  group('Pattern 003: BasicReplace', () {
    test('model toJson and fromJson', () {
      const result = Pattern003Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern003Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern003Service();
      final result = await service.run();
      expect(result, isA<Pattern003Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
