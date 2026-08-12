// Pattern 054: DeepLinkWeb - テスト
// Flutter Web のルーティングと URL 対応。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_054/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_054/service.dart';

void main() {
  group('Pattern 054: DeepLinkWeb', () {
    test('model toJson and fromJson', () {
      const result = Pattern054Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern054Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern054Service();
      final result = await service.run();
      expect(result, isA<Pattern054Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
