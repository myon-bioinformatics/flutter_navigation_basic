import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/navigation/route_names.dart';
import 'package:flutter_application_1/screens/generic_screen.dart';
import 'package:flutter_application_1/shared/display/display_catalog.dart';

// Keep the actual Dart constants and asset decoder observable. All integrity
// decisions live in the Python oracle, and the JSON can be inspected separately.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('export production metadata for Python integrity decisions', () async {
    ScreensConfig.resetCache();
    final screens = await ScreensConfig.load();
    final document = {
      'schemaVersion': 1,
      'routes': {
        'home': RouteNames.home,
        'counterPlayground': RouteNames.counterPlayground,
        'ironyGenerator': RouteNames.ironyGenerator,
        'compositionGenerator': RouteNames.compositionGenerator,
        'compositionSeedGenerator': RouteNames.compositionSeedGenerator,
        'boundingBox': RouteNames.boundingBox,
      },
      'locales': DisplayCatalog.supportedLocales,
      'namespaces': DisplayCatalog.requiredNamespaces,
      'screens': [
        for (final s in screens)
          {
            'screenDataId': s.screenDataId,
            'name': s.name,
            'title': s.title,
            'emoji': s.emoji,
            'description': s.description,
            'category': s.category,
            'navigationPattern': s.navigationPattern,
            'apiPattern': s.apiPattern,
            'themePattern': s.themePattern,
            'dataPattern': s.dataPattern,
            'domainKey': s.domainKey,
            'useCaseKey': s.useCaseKey,
            'templateJa': s.templateJa,
            'templateOverride': s.templateOverride,
            'detail': s.detail == null
                ? null
                : {
                    'purpose': s.detail!.purpose,
                    'when': s.detail!.when,
                    'points': s.detail!.points,
                    'pitfall': s.detail!.pitfall,
                    'snippet': s.detail!.snippet,
                  },
          },
      ],
    };
    final output = File('build/test-results/metadata-contracts.json');
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(document),
    );
    final result = await Process.run('python3', [
      '-S',
      'tool/python/metadata_contracts.py',
      output.path,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });
}
