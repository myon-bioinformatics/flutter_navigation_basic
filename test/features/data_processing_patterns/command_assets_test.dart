import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_051/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_052/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_053/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_001_to_099/pattern_054/view.dart';

class _RecordingBundle extends CachingAssetBundle {
  _RecordingBundle(this.payload);
  final String payload;
  String? requestedPath;
  @override Future<String> loadString(String key, {bool cache = true}) async { requestedPath = key; return payload; }
  @override Future<ByteData> load(String key) async { requestedPath = key; return ByteData.sublistView(Uint8List.fromList(utf8.encode(payload))); }
}

Widget _viewFor(int id, AssetBundle bundle) => switch (id) {
  51 => Pattern051View(bundle: bundle),
  52 => Pattern052View(bundle: bundle),
  53 => Pattern053View(bundle: bundle),
  54 => Pattern054View(bundle: bundle),
  _ => throw ArgumentError.value(id, 'id', 'Unknown command pattern'),
};

void main() {
  for (final id in [51, 52, 53, 54]) {
    final path = 'assets/data_processing/command_0$id.json';
    test('command 0$id reads shared JSON list asset', () async {
      final bundle = _RecordingBundle('{"schema":"collection-command/1","values":["ok"]}');
      expect(await JsonListAsset(path, bundle: bundle).load(), equals(['ok']));
      expect(bundle.requestedPath, path);
    });
    test('command 0$id rejects malformed JSON list asset', () async {
      final bundle = _RecordingBundle('{"schema":"collection-command/1"}');
      await expectLater(JsonListAsset(path, bundle: bundle).load(), throwsFormatException);
      expect(bundle.requestedPath, path);
    });
    testWidgets('command 0$id view selects its own asset', (tester) async {
      final bundle = _RecordingBundle('{"schema":"collection-command/1","values":["ok"]}');
      await tester.pumpWidget(MaterialApp(home: _viewFor(id, bundle)));
      await tester.tap(find.text('実行'));
      await tester.pumpAndSettle();
      expect(bundle.requestedPath, path);
      expect(find.textContaining('結果:'), findsOneWidget);
    });
  }
}
