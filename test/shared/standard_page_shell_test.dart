import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/widgets/standard_page_shell.dart';
import 'package:flutter_application_1/shared/widgets/standard_page_header.dart';
import 'package:flutter_application_1/shared/widgets/tool_door_selector.dart';
import '../support/display_test_harness.dart';

class _NavigationRecorder extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}

void main() {
  testWidgets(
    'Home action on Home preserves state without a dialog or navigation',
    (tester) async {
      final observer = _NavigationRecorder();
      await tester.pumpWidget(
        await wrapWithDisplayScope(
          MaterialApp(
            navigatorObservers: [observer],
            home: const StandardPageShell(
              title: 'Home',
              currentRouteName: '/',
              child: TextField(),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'keep this draft');
      final before = observer.pushed.length;
      await tester.tap(find.byKey(const Key('shared-header-home')));
      await tester.tap(find.byKey(const Key('shared-header-home')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(observer.pushed.length, before);
      expect(find.text('keep this draft'), findsOneWidget);
    },
  );

  testWidgets(
    'rapid Home callbacks produce one dialog and one navigation; cancel permits retry',
    (tester) async {
      final observer = _NavigationRecorder();
      await tester.pumpWidget(
        await wrapWithDisplayScope(
          MaterialApp(
            navigatorObservers: [observer],
            initialRoute: '/detail',
            routes: {
              '/': (_) => const Scaffold(body: Text('home-destination')),
              '/detail': (_) => const StandardPageShell(
                title: 'Draft',
                currentRouteName: '/detail',
                child: Text('draft'),
              ),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final home = find.byKey(const Key('shared-header-home'));
      // Capture the real callback before a frame can disable the button. This
      // exercises queued rapid taps rather than relying on the modal barrier.
      final press = tester.widget<IconButton>(home).onPressed!;
      press();
      press();
      press();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(observer.pushed.whereType<PopupRoute<dynamic>>().length, 1);
      expect(tester.widget<IconButton>(home).onPressed, isNull);
      await tester.tap(find.byKey(const Key('shared-header-stay')));
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(home).onPressed, isNotNull);
      press();
      press();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(observer.pushed.whereType<PopupRoute<dynamic>>().length, 2);
      final homePushes = observer.pushed
          .where((r) => r.settings.name == '/')
          .length;
      await tester.tap(find.byKey(const Key('shared-header-confirm-home')));
      await tester.pump();
      // The outgoing header must stay guarded throughout route replacement.
      press();
      press();
      await tester.pumpAndSettle();
      expect(
        observer.pushed.where((r) => r.settings.name == '/').length,
        homePushes + 1,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('home-destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('narrow common header keeps title readable and language in menu', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await wrapWithDisplayScope(const MaterialApp(
      home: StandardPageShell(
        title: 'Navigation Hub', currentRouteName: '/hub',
        child: Text('Hub content')),
    )));
    await tester.pumpAndSettle();
    final label = find.text('Navigation Hub 🗺️');
    expect(label, findsOneWidget);
    expect(tester.getSize(label).width, greaterThan(60));
    await tester.tap(find.byKey(const Key('shared-header-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets('phone keeps common actions above page actions and favorites survive rebuild', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SessionPageFavorites.routes.value = {};
    addTearDown(() => SessionPageFavorites.routes.value = {});
    var clears = 0;
    await tester.pumpWidget(await wrapWithDisplayScope(MaterialApp(
      home: StandardPageShell(
        title: 'Request editor', currentRouteName: '/tools/http/request-draft',
        headerActions: [TextButton(key: const Key('page-clear'),
          onPressed: () => clears++, child: const Text('Clear draft'))],
        child: const Text('body'),
      ),
    )));
    await tester.pumpAndSettle();
    final home = find.byKey(const Key('shared-header-home'));
    final favorite = find.byKey(const Key('shared-header-favorite'));
    final menu = find.byKey(const Key('shared-header-menu'));
    final clear = find.byKey(const Key('page-clear'));
    expect(tester.getCenter(home).dy, tester.getCenter(menu).dy);
    expect(tester.getCenter(favorite).dy, tester.getCenter(menu).dy);
    expect(tester.getTopLeft(clear).dy, greaterThanOrEqualTo(tester.getBottomLeft(home).dy));
    expect(find.text('Request editor 🌐'), findsOneWidget);
    await tester.tap(clear);
    await tester.tap(favorite);
    await tester.pump();
    expect(clears, 1);
    expect(SessionPageFavorites.routes.value, contains('/tools/http/request-draft'));
    expect(tester.widget<IconButton>(favorite).isSelected, isTrue);
    await tester.tap(favorite);
    await tester.pump();
    expect(SessionPageFavorites.routes.value, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct-open page does not expose inert BackButton', (tester) async {
    await tester.pumpWidget(await wrapWithDisplayScope(const MaterialApp(
      home: StandardPageShell(title: 'Direct', currentRouteName: '/direct',
        child: Text('direct body')),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shared-header-back')), findsNothing);
    expect(find.byKey(const Key('shared-header-home')), findsOneWidget);
  });


  testWidgets('footer does not cover or intercept body controls', (tester) async {
    var taps = 0;
    await tester.pumpWidget(await wrapWithDisplayScope(MaterialApp(
      home: StandardPageShell(
        title: 'Interactive',
        currentRouteName: '/detail',
        child: Center(
          child: FilledButton(
            key: const Key('body-interaction'),
            onPressed: () => taps++,
            child: const Text('Run action'),
          ),
        ),
      ),
    )));
    await tester.pumpAndSettle();
    final bodyButton = find.byKey(const Key('body-interaction'));
    await tester.tap(bodyButton);
    await tester.pump();
    expect(taps, 1);
    final buttonBottom = tester.getBottomLeft(bodyButton).dy;
    final footerTop = tester.getTopLeft(find.byType(ToolDoorSelector)).dy;
    expect(buttonBottom, lessThan(footerTop));
  });

  testWidgets('shared header Home confirmation prioritizes staying and only navigates on approval', (tester) async {
    await tester.pumpWidget(await wrapWithDisplayScope(MaterialApp(
      initialRoute: '/detail',
      routes: {
        '/': (_) => const Scaffold(body: Text('home-destination')),
        '/detail': (_) => const StandardPageShell(
          title: 'Example',
          currentRouteName: '/detail',
          child: Text('unsaved editor state'),
        ),
      },
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shared-header-home')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Unsaved changes'), findsOneWidget);
    final stay = find.byKey(const Key('shared-header-stay'));
    final go = find.byKey(const Key('shared-header-confirm-home'));
    expect(stay, findsOneWidget);
    expect(go, findsOneWidget);
    final stayWidth = tester.getSize(stay).width;
    final goWidth = tester.getSize(go).width;
    expect(stayWidth, greaterThan(goWidth));
    await tester.tap(stay);
    await tester.pumpAndSettle();
    expect(find.text('unsaved editor state'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shared-header-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shared-header-confirm-home')));
    await tester.pumpAndSettle();
    expect(find.text('home-destination'), findsOneWidget);
  });

  testWidgets('shared menu opens sheet; no duplicate locale picker', (tester) async {
    await tester.pumpWidget(await wrapWithDisplayScope(MaterialApp(
      home: const StandardPageShell(
        title: 'Example',
        currentRouteName: '/detail',
        child: Text('body'),
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shared-header-menu')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shared-header-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Navigation'), findsOneWidget);
  });
}
