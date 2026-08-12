// Pattern 079: AdaptiveNav - テスト
// 画面サイズに応じて切り替わるナビゲーション。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_079/model.dart';
import 'package:flutter_application_1/features/navigation_patterns/pattern_001_to_099/pattern_079/service.dart';

void main() {
  group('Pattern 079: AdaptiveNav', () {
    test('model toJson and fromJson', () {
      const result = Pattern079Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern079Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern079Service();
      final result = await service.run();
      expect(result, isA<Pattern079Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
