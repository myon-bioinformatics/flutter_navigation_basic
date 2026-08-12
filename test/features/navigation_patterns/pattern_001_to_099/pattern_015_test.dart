// Pattern 015: TabBarView - テスト
// TabController + TabBarView による横スクロールタブ。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_015/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_015/service.dart';

void main() {
  group('Pattern 015: TabBarView', () {
    test('model toJson and fromJson', () {
      const result = Pattern015Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern015Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern015Service();
      final result = await service.run();
      expect(result, isA<Pattern015Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
