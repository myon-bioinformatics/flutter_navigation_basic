// Pattern 112: HistoryView - テスト
// 遷移履歴を一覧表示。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_112/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_112/service.dart';

void main() {
  group('Pattern 112: HistoryView', () {
    test('model toJson and fromJson', () {
      const result = Pattern112Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern112Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern112Service();
      final result = await service.run();
      expect(result, isA<Pattern112Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
