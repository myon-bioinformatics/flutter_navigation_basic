// Pattern 023: PopupMenu - テスト
// PopupMenuButton の実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_023/model.dart';
import 'package:flutter_application_1/features/ui_theme_patterns/pattern_001_to_099/pattern_023/service.dart';

void main() {
  group('Pattern 023: PopupMenu', () {
    test('model toJson and fromJson', () {
      const result = Pattern023Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern023Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern023Service();
      final result = await service.run();
      expect(result, isA<Pattern023Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
