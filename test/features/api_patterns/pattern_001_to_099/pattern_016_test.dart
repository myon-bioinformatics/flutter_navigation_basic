// Pattern 016: Search - テスト
// 検索クエリ付き REST API 実装。
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_016/model.dart';
import 'package:flutter_application_1/features/api_patterns/pattern_001_to_099/pattern_016/service.dart';

void main() {
  group('Pattern 016: Search', () {
    test('model toJson and fromJson', () {
      const result = Pattern016Result(message: 'test');
      final json = result.toJson();
      expect(json['message'], equals('test'));
      final restored = Pattern016Result.fromJson(json);
      expect(restored.message, equals('test'));
    });

    test('service run completes', () async {
      final service = Pattern016Service();
      final result = await service.run();
      expect(result, isA<Pattern016Result>());
      expect(result.message, isNotEmpty);
    });
  });
}
