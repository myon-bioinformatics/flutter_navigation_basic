// Pattern 032: CupertinoNavBar - テスト
// CupertinoNavigationBar の実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_032/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_032/service.dart';

void main() {
  group('Pattern 032: CupertinoNavBar', () {
    test('model toJson and fromJson', () {
      const result = Pattern032Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern032Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern032Service();
      final result = await service.run();
      expect(result, isA<Pattern032Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
