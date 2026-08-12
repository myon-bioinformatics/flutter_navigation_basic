// Pattern 043: CupertinoContext - テスト
// CupertinoContextMenu の実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_043/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_043/service.dart';

void main() {
  group('Pattern 043: CupertinoContext', () {
    test('model toJson and fromJson', () {
      const result = Pattern043Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern043Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern043Service();
      final result = await service.run();
      expect(result, isA<Pattern043Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
