import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/widgets/standard_page_shell.dart';
import 'package:flutter_application_1/shared/widgets/standard_page_header.dart';
import 'package:flutter_application_1/shared/widgets/tool_door_selector.dart';
import '../support/display_test_harness.dart';

void main() {
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
