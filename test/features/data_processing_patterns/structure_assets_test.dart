import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';

class _RecordingBundle extends CachingAssetBundle {
  _RecordingBundle(this.payload);
  final String payload;
  String? requestedPath;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    requestedPath = key;
    return payload;
  }

  @override
  Future<ByteData> load(String key) async {
    requestedPath = key;
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(payload)));
  }
}

void main() {
  for (final id in [45, 46, 47, 48, 49]) {
    final path = 'assets/data_processing/structure_0$id.json';
    test('structure 0$id reads shared JSON list asset', () async {
      final bundle = _RecordingBundle('{"schema":"collection-structure/1","values":["ok"]}');
      final asset = JsonListAsset(path, bundle: bundle);
      expect(await asset.load(), equals(['ok']));
      expect(bundle.requestedPath, path);
    });

    test('structure 0$id rejects malformed JSON list asset', () async {
      final bundle = _RecordingBundle('{"schema":"collection-structure/1"}');
      final asset = JsonListAsset(path, bundle: bundle);
      await expectLater(asset.load(), throwsFormatException);
      expect(bundle.requestedPath, path);
    });
  }
}
