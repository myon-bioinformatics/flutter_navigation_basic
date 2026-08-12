// Pattern 184: TusProtocol - テスト
// TUS プロトコル対応アップロード (擬似)。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_184/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_100_to_198/pattern_184/service.dart';

void main() {
  group('Pattern 184: TusProtocol', () {
    test('model toJson and fromJson', () {
      const result = Pattern184Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern184Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern184Service();
      final result = await service.run();
      expect(result, isA<Pattern184Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
