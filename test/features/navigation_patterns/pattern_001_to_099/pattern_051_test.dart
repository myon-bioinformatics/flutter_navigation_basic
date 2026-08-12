// Pattern 051: DeepLinkNotification - テスト
// プッシュ通知からのディープリンク。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_051/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_051/service.dart';

void main() {
  group('Pattern 051: DeepLinkNotification', () {
    test('model toJson and fromJson', () {
      const result = Pattern051Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern051Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern051Service();
      final result = await service.run();
      expect(result, isA<Pattern051Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
