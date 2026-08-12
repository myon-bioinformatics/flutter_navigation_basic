// Pattern 059: DeepLinkAnalytics - テスト
// ディープリンク遷移をアナリティクス送信。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_059/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_059/service.dart';

void main() {
  group('Pattern 059: DeepLinkAnalytics', () {
    test('model toJson and fromJson', () {
      const result = Pattern059Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern059Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern059Service();
      final result = await service.run();
      expect(result, isA<Pattern059Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
