import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_026/service.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.payload);
  final String payload;
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(payload)));
  @override
  Future<String> loadString(String key, {bool cache = true}) async => payload;
}

void main() {
  test('pattern 026 loads externally ordered collection values', () async {
    final service = Pattern026Service(bundle: _Bundle(
      '{"schema":"list-ordering/1","mode":"test","values":[3,2,1]}',
    ));
    expect(await service.load(), equals([3, 2, 1]));
  });

  test('pattern 026 rejects malformed generated data', () async {
    final service = Pattern026Service(bundle: _Bundle('{"schema":"list-ordering/1"}'));
    await expectLater(service.load(), throwsFormatException);
  });
}
