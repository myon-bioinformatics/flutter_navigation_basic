// Pattern 080: EventBus - テスト
// アプリ内イベントバスによる非同期通信。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_080/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_080/service.dart';

void main() {
  group('Pattern 080: EventBus', () {
    test('model toJson and fromJson', () {
      const result = Pattern080Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern080Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern080Service();
      final result = await service.run();
      expect(result, isA<Pattern080Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
