// Pattern 178: MergeSemantics - テスト
// MergeSemantics による意味合の統合。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_178/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_100_to_198/pattern_178/service.dart';

void main() {
  group('Pattern 178: MergeSemantics', () {
    test('model toJson and fromJson', () {
      const result = Pattern178Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern178Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern178Service();
      final result = await service.run();
      expect(result, isA<Pattern178Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
