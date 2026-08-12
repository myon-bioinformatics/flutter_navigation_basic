// Pattern 010: BackButtonHandler - テスト
// Android バックキーを横取りして確認ダイアログ。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_010/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_010/service.dart';

void main() {
  group('Pattern 010: BackButtonHandler', () {
    test('model toJson and fromJson', () {
      const result = Pattern010Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern010Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern010Service();
      final result = await service.run();
      expect(result, isA<Pattern010Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
