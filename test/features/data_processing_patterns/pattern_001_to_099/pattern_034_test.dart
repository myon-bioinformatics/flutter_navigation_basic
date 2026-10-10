import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_034/service.dart';

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
  test('pattern 034 loads externally computed window state', () async {
    final service = Pattern034Service(bundle: _Bundle(
      '{"schema":"collection-window/1","mode":"test","values":["item-05"]}',
    ));
    expect(await service.load(), equals(["item-05"]));
  });

  test('pattern 034 rejects malformed generated data', () async {
    final service = Pattern034Service(bundle: _Bundle('{"schema":"collection-window/1"}'));
    await expectLater(service.load(), throwsFormatException);
  });
}
