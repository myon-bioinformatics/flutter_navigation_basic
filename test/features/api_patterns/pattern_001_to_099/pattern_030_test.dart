// Pattern 030: BaseUrl - テスト
// ベース URL + エンドポイントの構造化実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_030/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_030/service.dart';

void main() {
  group('Pattern 030: BaseUrl', () {
    test('model toJson and fromJson', () {
      const result = Pattern030Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern030Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern030Service();
      final result = await service.run();
      expect(result, isA<Pattern030Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
