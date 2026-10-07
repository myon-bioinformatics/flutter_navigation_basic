import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_047/service.dart';
class _Bundle extends CachingAssetBundle {
  _Bundle(this.payload); final String payload;
  @override Future<ByteData> load(String key) async => ByteData.sublistView(Uint8List.fromList(utf8.encode(payload)));
  @override Future<String> loadString(String key, {bool cache = true}) async => payload;
}
void main() {
  test('pattern 047 loads Python-generated structure', () async {
    final service=Pattern047Service(bundle:_Bundle('{"schema":"collection-structure/1","values":["ok"]}'));
    expect(await service.load(), equals(["ok"]));
  });
  test('pattern 047 rejects malformed data', () async {
    final service=Pattern047Service(bundle:_Bundle('{"schema":"collection-structure/1"}'));
    await expectLater(service.load(), throwsFormatException);
  });
}
