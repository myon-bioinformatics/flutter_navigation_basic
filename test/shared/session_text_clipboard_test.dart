import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/widgets/session_text_clipboard.dart';
import 'package:flutter_application_1/shared/widgets/standard_page_shell.dart';

void main() {
  setUp(SessionTextClipboard.clear);
  tearDown(SessionTextClipboard.clear);

  test('memory-only entries deduplicate, reject empty and oversize text', () {
    expect(SessionTextClipboard.save('one'), isTrue);
    expect(SessionTextClipboard.save('two'), isTrue);
    expect(SessionTextClipboard.save('one'), isTrue);
    expect(SessionTextClipboard.entries.value, ['one', 'two']);
    expect(SessionTextClipboard.save(''), isFalse);
    expect(SessionTextClipboard.save(List.filled(SessionTextClipboard.maxChars + 1, 'x').join()), isFalse);
    expect(SessionTextClipboard.entries.value, ['one', 'two']);
    SessionTextClipboard.clear();
    expect(SessionTextClipboard.entries.value, isEmpty);
  });

  testWidgets('drawer saves clipboard text, persists across routes, and copies back',
      (tester) async {
    String clipboardText = 'Copied before opening menu';
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': clipboardText};
      if (call.method == 'Clipboard.setData') {
        clipboardText = (call.arguments as Map)['text'] as String;
        return null;
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));

    Widget screen(String title) => StandardPageShell(
      title: title, currentRouteName: '/detail',
      child: Text(title),
    );
    await tester.pumpWidget(MaterialApp(
      initialRoute: '/first',
      routes: {
        '/first': (_) => screen('First screen'),
        '/second': (_) => screen('Second screen'),
      },
    ));
    await tester.tap(find.byKey(const Key('shared-header-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('session-clipboard-save')));
    await tester.pumpAndSettle();
    expect(SessionTextClipboard.entries.value, ['Copied before opening menu']);

    await tester.pageBack();
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/second');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shared-header-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Copied before opening menu'), findsOneWidget);
    clipboardText = 'overwritten';
    await tester.tap(find.byKey(const Key('session-clipboard-copy-0')));
    await tester.pumpAndSettle();
    expect(clipboardText, 'Copied before opening menu');
  });
}
