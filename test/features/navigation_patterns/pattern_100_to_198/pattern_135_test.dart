// Pattern 135: ModalStack - テスト
// モーダルスタックを独立 Navigator で管理。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_135/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_100_to_198/pattern_135/service.dart';

void main() {
  group('Pattern 135: ModalStack', () {
    test('model toJson and fromJson', () {
      const result = Pattern135Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern135Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern135Service();
      final result = await service.run();
      expect(result, isA<Pattern135Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
