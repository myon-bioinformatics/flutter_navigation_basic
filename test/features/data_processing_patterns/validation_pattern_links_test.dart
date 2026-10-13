import '../../support/display_test_harness.dart';
import '../../support/header_finders.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/config/routes.dart';

/// Same define the widget reads: CI runs this file once without it (main) and
/// once with --dart-define=SOURCE_REF=<sha> to prove commit pinning.
const _ref = String.fromEnvironment('SOURCE_REF', defaultValue: 'main');
const _base = 'https://github.com/myon-bioinformatics/flutter_navigation_basic/blob/$_ref/';
const _links = <String, String>{
  'Python実装': '${_base}tool/python/validation_patterns.py',
  'Pythonテスト': '${_base}tool/python/tests/test_validation_patterns.py',
  'ローカル入力画面': '${_base}tool/python/validation_http.py',
  '利用方法・制約': '${_base}docs/data-processing-validation-091-099.md',
};
const _names = <int, String>{
  91: 'ValidationBasic', 92: 'EmailValidation', 93: 'PasswordStrength',
  94: 'PhoneValidation', 95: 'UrlValidation', 96: 'DateValidation',
  97: 'RangeValidation', 98: 'RegexValidation', 99: 'FormValidation',
};

Future<void> _open(WidgetTester tester, int id) async {
  final route = AppRoutes.routes[AppRoutes.screenRoute(id)];
  expect(route, isNotNull, reason: 'missing /screen$id');
  await tester.pumpWidget(await wrapWithDisplayScope(MaterialApp(home: Builder(builder: route!))));
}

void main() {
  for (final entry in _names.entries) {
    testWidgets('screen${entry.key} shows its title and the four source URLs',
        (tester) async {
      await _open(tester, entry.key);
      expect(pageHeaderTitle('Pattern 0${entry.key}: ${entry.value}'), findsOneWidget);
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
    await _open(tester, 91);
    for (final label in _links.keys) {
      await tester.tap(find.byTooltip('$label のURLをコピー'));
      await tester.pump();
      expect(find.text('$label のURLをコピーしました'), findsOneWidget);
      // Drop the SnackBar so the next one is shown instead of queued.
      ScaffoldMessenger.of(tester.element(find.byType(ListView)))
          .removeCurrentSnackBar();
      await tester.pump();
    }
    expect(copied, _links.values.toList());
  });
}
