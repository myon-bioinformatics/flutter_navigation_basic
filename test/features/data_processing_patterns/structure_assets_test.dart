import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_045/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_046/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_047/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_048/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_049/view.dart';

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

Widget _viewFor(int id, AssetBundle bundle) => switch (id) {
  45 => Pattern045View(bundle: bundle),
  46 => Pattern046View(bundle: bundle),
  47 => Pattern047View(bundle: bundle),
  48 => Pattern048View(bundle: bundle),
  49 => Pattern049View(bundle: bundle),
  _ => throw ArgumentError.value(id, 'id', 'Unknown structure pattern'),
};

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

    testWidgets('structure 0$id view selects its own asset', (tester) async {
      final bundle = _RecordingBundle('{"schema":"collection-structure/1","values":["ok"]}');
      await tester.pumpWidget(MaterialApp(home: _viewFor(id, bundle)));
      await tester.tap(find.text('実行'));
      await tester.pumpAndSettle();
      expect(bundle.requestedPath, path);
      expect(find.textContaining('結果:'), findsOneWidget);
    });
  }
}
