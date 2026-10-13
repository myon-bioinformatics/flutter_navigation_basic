import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/display/display_catalog.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:flutter_application_1/shared/widgets/session_text_clipboard.dart';
import 'package:flutter_application_1/shared/widgets/standard_page_header.dart';
import 'package:flutter_application_1/shared/widgets/standard_page_shell.dart';

import '../support/display_test_harness.dart';

void main() {
  setUp(() {
    SessionTextClipboard.clear();
    SessionPageFavorites.routes.value = {};
  });
  tearDown(() {
    SessionTextClipboard.clear();
    SessionPageFavorites.routes.value = {};
  });

  testWidgets('all locales update open menu, tooltips and Home confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final display = await loadTestDisplayController();
    final navigator = GlobalKey<NavigatorState>();
    // Put the scope below Navigator to exercise overlay scope propagation.
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        initialRoute: '/detail',
        routes: {
          '/': (_) => const Scaffold(body: Text('home-destination')),
          '/detail': (_) => DisplayScope(
            controller: display,
            child: const StandardPageShell(
              title: 'Draft',
              currentRouteName: '/detail',
              child: TextField(),
            ),
          ),
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'keep me');
    await tester.tap(find.byKey(const Key('shared-header-menu')));
    await tester.pumpAndSettle();
    for (final locale in DisplayCatalog.supportedLocales) {
      await display.setLocale(locale);
      await tester.pumpAndSettle();
      for (final key in [
        'header.language',
        'header.favorites',
        'sessionClipboard.title',
        'sessionClipboard.save',
        'sessionClipboard.empty',
      ]) {
        expect(
          find.text(display.text(key)),
          findsOneWidget,
          reason: '$locale:$key',
        );
      }
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('shared-header-home')))
            .tooltip,
        display.text('header.home'),
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('shared-header-menu')))
            .tooltip,
        display.text('header.menu'),
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('shared-header-favorite')))
            .tooltip,
        display.text('header.favorite'),
      );
      expect(tester.takeException(), isNull, reason: locale);
    }
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shared-header-favorite')));
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('shared-header-favorite')))
          .tooltip,
      display.text('header.removeFavorite'),
    );
    await tester.tap(find.byKey(const Key('shared-header-home')));
    await tester.pumpAndSettle();
    for (final locale in DisplayCatalog.supportedLocales) {
      await display.setLocale(locale);
      await tester.pumpAndSettle();
      expect(find.text(display.text('header.confirmTitle')), findsOneWidget);
      expect(
        find.text(
          display.text('header.confirmBody', arguments: {'title': 'Draft'}),
        ),
        findsOneWidget,
      );
      final stay = find.byKey(const Key('shared-header-stay'));
      final home = find.byKey(const Key('shared-header-confirm-home'));
      expect(
        find.descendant(
          of: stay,
          matching: find.text(display.text('header.stay')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: home,
          matching: find.text(display.text('header.home')),
        ),
        findsOneWidget,
      );
      expect(tester.widget(stay), isA<FilledButton>());
      expect(
        tester.getSize(stay).width,
        greaterThan(tester.getSize(home).width),
      );
      await tester.tapAt(const Offset(8, 80));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull, reason: locale);
    }
    await tester.tap(find.byKey(const Key('shared-header-stay')));
    await tester.pumpAndSettle();
    expect(find.text('keep me'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shared-header-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shared-header-confirm-home')));
    await tester.pumpAndSettle();
    expect(find.text('home-destination'), findsOneWidget);
  });

  testWidgets(
    'clipboard outcomes and existing feedback follow locale; failures preserve entries',
    (tester) async {
      final display = await loadTestDisplayController();
      String? text;
      var failRead = false;
      var failCopy = false;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') {
          if (failRead) throw PlatformException(code: 'denied');
          return text == null ? null : {'text': text};
        }
        if (call.method == 'Clipboard.setData') {
          if (failCopy) throw PlatformException(code: 'denied');
          text = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tester.pumpWidget(
        DisplayScope(
          controller: display,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SessionClipboardDrawerSection(),
              ),
            ),
          ),
        ),
      );
      Future<void> outcome(String control, String key) async {
        await tester.tap(find.byKey(Key(control)));
        await tester.pumpAndSettle();
        for (final locale in DisplayCatalog.supportedLocales) {
          await display.setLocale(locale);
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<Text>(
                  find.byKey(const Key('session-clipboard-feedback')),
                )
                .data,
            display.text(key),
            reason: '$locale:$key',
          );
          expect(tester.takeException(), isNull);
        }
      }

      await outcome('session-clipboard-save', 'sessionClipboard.noText');
      text = '';
      await outcome('session-clipboard-save', 'sessionClipboard.noText');
      text = 'saved user text';
      await outcome('session-clipboard-save', 'sessionClipboard.saved');
      expect(SessionTextClipboard.entries.value, ['saved user text']);
      text = List.filled(SessionTextClipboard.maxChars + 1, 'x').join();
      await outcome('session-clipboard-save', 'sessionClipboard.tooLarge');
      failRead = true;
      await outcome('session-clipboard-save', 'sessionClipboard.readFailed');
      failCopy = true;
      await outcome('session-clipboard-copy-0', 'sessionClipboard.copyFailed');
      expect(SessionTextClipboard.entries.value, ['saved user text']);
      failCopy = false;
      await outcome('session-clipboard-copy-0', 'sessionClipboard.copied');
      expect(text, 'saved user text');
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const Key('session-clipboard-copy-0')),
            )
            .tooltip,
        display.text('sessionClipboard.copy'),
      );
    },
  );
  testWidgets(
    'standalone header and clipboard preserve the no-scope contract',
    (tester) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData')
          return {'text': 'standalone text'};
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          initialRoute: '/detail',
          routes: {
            '/': (_) => const Scaffold(body: Text('home-destination')),
            '/detail': (_) => const Scaffold(
              appBar: StandardPageHeader(
                title: 'Standalone',
                currentRouteName: '/detail',
              ),
              body: Text('draft'),
            ),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('shared-header-home')))
            .tooltip,
        'Home',
      );
      await tester.tap(find.byKey(const Key('shared-header-menu')));
      await tester.pumpAndSettle();
      expect(find.byType(DisplayLocalePicker), findsNothing);
      expect(find.text('Temporary clipboard'), findsOneWidget);
      await tester.tap(find.byKey(const Key('session-clipboard-save')));
      await tester.pumpAndSettle();
      expect(find.text('Saved to temporary clipboard'), findsOneWidget);
      await tester.tap(find.byKey(const Key('session-clipboard-copy-0')));
      await tester.pumpAndSettle();
      expect(find.text('Copied to system clipboard'), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shared-header-home')));
      await tester.pumpAndSettle();
      expect(find.text('Return to Home?'), findsOneWidget);
      expect(
        find.text(
          'Leave Standalone? Unsaved changes on this screen may be lost.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('shared-header-stay')));
      await tester.pumpAndSettle();
      expect(find.text('draft'), findsOneWidget);
      await tester.tap(find.byKey(const Key('shared-header-home')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shared-header-confirm-home')));
      await tester.pumpAndSettle();
      expect(find.text('home-destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
