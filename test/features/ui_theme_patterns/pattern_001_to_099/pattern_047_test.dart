// Pattern 047: CupertinoProgress - テスト
// CupertinoActivityIndicator の実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_047/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_047/service.dart';

void main() {
  group('Pattern 047: CupertinoProgress', () {
    test('model toJson and fromJson', () {
      const result = Pattern047Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern047Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern047Service();
      final result = await service.run();
      expect(result, isA<Pattern047Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
