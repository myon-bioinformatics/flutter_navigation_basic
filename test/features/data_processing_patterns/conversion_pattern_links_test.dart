import '../../support/header_finders.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/config/routes.dart';

/// Same define the widget reads: CI runs this file without it (main) and with
/// --dart-define=SOURCE_REF=<sha> to prove commit pinning.
const _ref = String.fromEnvironment('SOURCE_REF', defaultValue: 'main');
const _base = 'https://github.com/myon-bioinformatics/flutter_navigation_basic/blob/$_ref/';
const _links = <String, String>{
  'Python実装': '${_base}python/conversion_patterns.py',
  'Pythonテスト': '${_base}python/tests/test_conversion_patterns.py',
  '利用方法・制約': '${_base}docs/data-processing-conversion-103-110.md',
};
const _names = <int, String>{
  103: 'DataNormalize', 104: 'TypeCoercion', 105: 'DateConvert',
  107: 'UnitConvert', 109: 'Encoding', 110: 'DataMasking',
};

Future<void> _open(WidgetTester tester, int id) async {
  final route = AppRoutes.routes[AppRoutes.screenRoute(id)];
  expect(route, isNotNull, reason: 'missing /screen$id');
  await tester.pumpWidget(MaterialApp(home: Builder(builder: route!)));
}

void main() {
  for (final entry in _names.entries) {
    testWidgets('screen${entry.key} shows its title and the three source URLs',
        (tester) async {
      await _open(tester, entry.key);
      expect(pageHeaderTitle('Pattern ${entry.key}: ${entry.value}'), findsOneWidget);
      expect(find.textContaining('限定実装'), findsOneWidget);
      expect(find.text('実行'), findsNothing);
      final shown = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .map((widget) => widget.data)
          .toList();
      expect(shown, _links.values.toList());
    });
  }

  testWidgets('each copy button copies exactly its own URL', (tester) async {
    final copied = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance
        .defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await _open(tester, 110);
    for (final label in _links.keys) {
      await tester.tap(find.byTooltip('$label のURLをコピー'));
      await tester.pump();
      expect(find.text('$label のURLをコピーしました'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(ListView)))
          .removeCurrentSnackBar();
      await tester.pump();
    }
    expect(copied, _links.values.toList());
  });
}
